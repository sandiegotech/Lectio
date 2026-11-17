import SwiftUI
import UIKit

struct LibraryView: View {
    @EnvironmentObject var library: Library
    @EnvironmentObject var reading: ReadingState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize
    @StateObject private var opener = BookOpener()
    @State private var path = NavigationPath()
    @State private var browseMode: BrowseMode = .myBooks
    @State private var forceStarter = false   // DEBUG: LECTIO_DEBUG_FIRST_LAUNCH
    @State private var showSearch = false
    @State private var searchSeed = ""
    @State private var openFromSearch: Work?
    @AppStorage("library.sort") private var sort: LibrarySort = .timeline
    private var pal: Palette { Palette.forScheme(colorScheme) }

    enum BrowseMode: Hashable { case myBooks, library, explore }

    // The books this reader has opened and can still open, most recent first.
    private var myBookWorks: [Work] { reading.openedWorkIds.compactMap { library.work(id: $0) } }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if browseMode == .explore {
                    // Explore pages through its own cards, so it has its own scroll.
                    VStack(spacing: 14) {
                        browseToggle.padding(.top, 8)
                        ExploreFeed()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 26) {
                            browseToggle
                            if browseMode == .myBooks { myBooks } else { libraryPage }
                            instituteCredit
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 18)
                    }
                    .defaultScrollAnchor(initialScrollAnchor)
                }
            }
            .safeAreaInset(edge: .top) { header }
            .background(pal.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Work.self) { work in
                ReaderView(work: work)
            }
            .navigationDestination(for: ReaderRoute.self) { route in
                if let work = library.work(id: route.workId) {
                    ReaderView(work: work, initialTarget: route.target)
                }
            }
            .navigationDestination(for: BookOverview.self) { BookOverviewView(book: $0) }
            .navigationDestination(for: Concept.self) { ConceptDetailView(concept: $0) }
            .navigationDestination(for: WordStudy.self) { WordStudyView(study: $0) }
        }
        .overlay { BookOpeningOverlay() }
        .environmentObject(opener)
        // A search result opens on this stack, once the sheet is gone, so every link
        // inside the reader (word study, overviews) has its destinations.
        .sheet(isPresented: $showSearch, onDismiss: {
            if let w = openFromSearch { openFromSearch = nil; path.append(w) }
        }) {
            SearchView(initialQuery: searchSeed) { w in
                openFromSearch = w
                showSearch = false
            }
        }
        .onAppear {
            opener.push = { route in
                switch route {
                case .work(let w): path.append(w)
                case .reader(let r): path.append(r)
                }
            }
            reading.backfillProgress(using: library)
            #if DEBUG
            debugHooks()
            #endif
        }
    }

    #if DEBUG
    // Debug hooks for headless screenshots. Debug builds only.
    private func debugHooks() {
        let env = ProcessInfo.processInfo.environment
        // LECTIO_DEBUG_FIRST_LAUNCH shows My Books as on a first launch (the starter book).
        if env["LECTIO_DEBUG_FIRST_LAUNCH"] != nil { forceStarter = true }
        if let q = env["LECTIO_DEBUG_SEARCH"] { searchSeed = q; showSearch = true }
        // LECTIO_DEBUG_SEED_READING=<workId> seeds a reading position partway into that
        // work, so the Continue-reading card shows.
        if let wid = env["LECTIO_DEBUG_SEED_READING"], let w = library.work(id: wid),
           reading.state(wid)?.segmentId == nil,
           let ed = library.edition(w.defaultEditionId) {
            let sec = ed.sections.count > 3 ? ed.sections[3] : ed.sections.first
            let seg = sec?.segments.first?.id
            let p = ed.progress(segmentId: seg)
            reading.savePosition(workId: w.id, editionId: ed.id, sectionId: sec?.id, segmentId: seg,
                                 place: ed.place(sectionId: sec?.id, progress: p), progress: p)
        }
        // LECTIO_DEBUG_BOOK=<title> opens that book's overview page.
        if let bt = env["LECTIO_DEBUG_BOOK"], let ov = library.bookOverview(title: bt) {
            path.append(ov)
        }
        // LECTIO_OPEN_WORK=<workId> opens straight into the reader.
        if let wid = env["LECTIO_OPEN_WORK"], let work = library.work(id: wid) {
            path.append(work)
        }
        // LECTIO_DEBUG_STUDY=<workId>|<term> opens the word-study page.
        if let spec = env["LECTIO_DEBUG_STUDY"] {
            let parts = spec.split(separator: "|", maxSplits: 1).map(String.init)
            if parts.count == 2 { path.append(WordStudy(term: parts[1], workId: parts[0])) }
        }
        // LECTIO_DEBUG_CONCEPT=<conceptId> opens that concept's page.
        if let cid = env["LECTIO_DEBUG_CONCEPT"], let c = library.concept(id: cid) {
            path.append(c)
        }
        // LECTIO_DEBUG_EXPLORE / LECTIO_DEBUG_LIBRARY open that section.
        if env["LECTIO_DEBUG_EXPLORE"] != nil { browseMode = .explore }
        if env["LECTIO_DEBUG_LIBRARY"] != nil { browseMode = .library }
    }
    #endif

    // LECTIO_DEBUG_BOTTOM (Debug only) opens the library scrolled to the bottom.
    private var initialScrollAnchor: UnitPoint {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LECTIO_DEBUG_BOTTOM"] != nil { return .bottom }
        #endif
        return .top
    }

    private var gutter: CGFloat { hSize == .regular ? 26 : 20 }

    // MARK: My Books — the books this reader has opened, the latest one featured.

    @ViewBuilder
    private var myBooks: some View {
        let books = forceStarter ? [] : myBookWorks
        if let first = books.first {
            FeaturedBook(work: first)
                .padding(.horizontal, gutter)
            if books.count > 1 {
                ShelfRows(works: Array(books.dropFirst()), inMyBooks: true)
                    .padding(.horizontal, gutter)
                    .padding(.top, 8)
            }
        } else {
            // Nothing opened yet: one book waits on the desk. A presentation rule, not a
            // saved position — opening any book replaces it with the reader's own.
            StarterBook(work: library.work(id: StarterBook.workId)) { browseMode = .library }
                .padding(.horizontal, gutter)
        }
    }

    // A quiet entry to the reader's own notes (saved words + highlights), off the shelves.
    private var notesButton: some View {
        NavigationLink(destination: NotesView()) {
            HStack(spacing: 5) {
                Image(systemName: "bookmark").font(.caption2)
                Text("Notes").font(.caption.weight(.medium))
            }
            .foregroundColor(pal.inkSoft)
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(Capsule().fill(pal.paper))
            .overlay(Capsule().stroke(pal.rule))
        }
    }

    // Three ways in: your books, the whole library, or Explore (a famous-line doorway).
    private var browseToggle: some View {
        Picker("Browse", selection: $browseMode) {
            Text("My Books").tag(BrowseMode.myBooks)
            Text("Library").tag(BrowseMode.library)
            Text("Explore").tag(BrowseMode.explore)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, gutter)
        .tint(pal.accent)
    }

    // MARK: header — a slim masthead pinned at the top, leaving the shelves the room.

    private var header: some View {
        HStack(spacing: 14) {
            Text("Lectio")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundColor(pal.ink)
            Image(systemName: "diamond.fill").font(.system(size: 5)).foregroundColor(pal.accent)
            Spacer()
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass").font(.subheadline.weight(.medium))
                    .foregroundColor(pal.inkSoft)
            }
            notesButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(pal.paper)
        .overlay(alignment: .bottom) { Divider().overlay(pal.rule) }
    }

    // MARK: the library — every readable work, sorted as the reader chooses.

    private var libraryPage: some View {
        VStack(alignment: .leading, spacing: 26) {
            sortTabs
            ForEach(sort.groups(library.works, collections: library.collections), id: \.title) { group in
                VStack(alignment: .leading, spacing: 14) {
                    if !group.title.isEmpty {
                        Text(group.title)
                            .font(.system(.title3, design: .serif)).foregroundColor(pal.ink)
                    }
                    ShelfRows(works: group.works, showDate: sort == .timeline)
                }
            }
        }
        .padding(.horizontal, gutter)
    }

    // Timeline · Genre · Collection · Title · Author — the selected one in red, underlined.
    private var sortTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: hSize == .regular ? 26 : 18) {
                ForEach(LibrarySort.allCases) { option in
                    let on = option == sort
                    Button { withAnimation(.easeInOut(duration: 0.2)) { sort = option } } label: {
                        Text(option.label)
                            .font(.system(size: hSize == .regular ? 17 : 15.5, weight: on ? .semibold : .regular, design: .serif))
                            .foregroundColor(on ? pal.accent : pal.ink.opacity(0.72))
                            .padding(.bottom, 5)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(on ? pal.accent : .clear).frame(height: 2)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
        .accessibilityLabel("Sort the library")
    }

    // MARK: institute credit

    private var instituteCredit: some View {
        VStack(spacing: 3) {
            Text("Built by the San Diego Institute of Technology")
                .font(.system(size: 10.5, weight: .medium))
                .tracking(0.4)
                .foregroundColor(pal.inkSoft.opacity(0.7))
            Text(appVersion)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(pal.inkSoft.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // App version + build, read from the bundle (set via MARKETING_VERSION / CURRENT_PROJECT_VERSION).
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "—"
        let b = info?["CFBundleVersion"] as? String
        return b.map { "Version \(v) (\($0))" } ?? "Version \(v)"
    }
}

enum LibrarySort: String, CaseIterable, Identifiable {
    case timeline, genre, collection, title, author
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    // Headed groups for the Library page; an empty title means one plain list.
    func groups(_ works: [Work], collections: [BookCollection]) -> [(title: String, works: [Work])] {
        let byYear = works.sorted { $0.sortYear < $1.sortYear }
        switch self {
        case .timeline:
            return [("", byYear)]
        case .genre:
            let order = ["Epic & Poetry", "Philosophy", "Scripture & Religion", "Politics", "Drama", "Other"]
            return order.map { g in (g, byYear.filter { $0.genre == g }) }.filter { !$0.1.isEmpty }
        case .collection:
            // Each series collection's readable books, in the collection's own order; a book
            // can sit under more than one. Collections with nothing readable are skipped.
            return collections.compactMap { c in
                let members = c.items.compactMap { item in works.first { $0.id == item.workId } }
                return members.isEmpty ? nil : (c.title, members)
            }
        case .title:
            return [("", works.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })]
        case .author:
            return [("", works.sorted {
                $0.author == $1.author ? $0.sortYear < $1.sortYear
                    : $0.author.localizedStandardCompare($1.author) == .orderedAscending
            })]
        }
    }
}

extension Work {
    var genre: String {
        switch type {
        case "epic_poem": return "Epic & Poetry"
        case "philosophy": return "Philosophy"
        case "religion", "scripture": return "Scripture & Religion"
        case "politics": return "Politics"
        case "drama": return "Drama"
        default: return "Other"
        }
    }
}

// A cover at its natural proportions: the bundled art, or the drawn clothbound card,
// with the progress ribbon once the book has been started.
struct BookCoverArt: View {
    let work: Work
    var progress: Double?
    var shadow = true
    @EnvironmentObject var library: Library

    var body: some View {
        Color.clear
            .aspectRatio(908.0 / 1403.0, contentMode: .fit)
            .overlay {
                if let img = CoverCache.image(at: library.coverURL(work.id)) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    SpineCard(work: work, height: nil)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
            .overlay { if let progress, progress > 0 { ProgressRibbon(progress: progress) } }
            .shadow(color: .black.opacity(shadow ? 0.28 : 0), radius: 9, x: 0, y: 5)
    }
}

// Books standing in rows on a shelf: covers on a slim shelf line with a soft
// reflection, title and author beneath. Two columns on a small iPhone, three on a
// larger one, ~150pt covers on iPad.
struct ShelfRows: View {
    let works: [Work]
    var inMyBooks = false
    var showDate = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var width: CGFloat = 0

    private static let aspect: CGFloat = 1403.0 / 908.0
    private static let reflection: CGFloat = 24

    var body: some View {
        let pal = Palette.forScheme(colorScheme)
        let spacing: CGFloat = hSize == .regular ? 30 : 18
        let n = hSize == .regular ? max(3, Int((width + spacing) / (150 + spacing))) : (width < 350 ? 2 : 3)
        let itemW = max(1, (width - spacing * CGFloat(n - 1)) / CGFloat(n))
        let rows = stride(from: 0, to: works.count, by: n).map { Array(works[$0..<min($0 + n, works.count)]) }
        VStack(alignment: .leading, spacing: 30) {
            ForEach(rows, id: \.first?.id) { row in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(row) { BookCard(work: $0, width: itemW, inMyBooks: inMyBooks, showDate: showDate) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .topLeading) {
                    Rectangle()
                        .fill(LinearGradient(colors: [pal.inkSoft.opacity(0.55), pal.inkSoft.opacity(0.12)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: width + 12, height: 2)
                        .shadow(color: .black.opacity(0.14), radius: 4, y: 3)
                        .offset(x: -6, y: itemW * Self.aspect + Self.reflection)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w in
            if abs(w - width) > 0.5 { width = w }
        }
    }
}

// One book on the shelf. In the Library a tap opens its overview; in My Books it opens
// the book itself, and a long press offers to take it off.
struct BookCard: View {
    let work: Work
    let width: CGFloat
    var inMyBooks = false
    var showDate = false
    @EnvironmentObject var reading: ReadingState
    @EnvironmentObject var opener: BookOpener
    @Environment(\.colorScheme) private var colorScheme
    @State private var cover = CoverFrame()

    var body: some View {
        let pal = Palette.forScheme(colorScheme)
        let progress = reading.state(work.id)?.progress
        let label = VStack(alignment: .leading, spacing: 0) {
            BookCoverArt(work: work, progress: progress)
                .frame(width: width)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cover.frame = $0 }
                .opacity(opener.opening?.work.id == work.id ? 0 : 1)
            // The cover's soft reflection on the shelf.
            BookCoverArt(work: work, shadow: false)
                .frame(width: width, height: width * 1403.0 / 908.0)
                .scaleEffect(y: -1, anchor: .center)
                .frame(height: 24, alignment: .top)
                .clipped()
                .opacity(0.14)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                .allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 2) {
                Text(work.title)
                    .font(.system(.subheadline, design: .serif).weight(.medium))
                    .foregroundColor(pal.ink).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(work.author).font(.caption).foregroundColor(pal.inkSoft).lineLimit(1)
                if showDate || progress != nil {
                    (Text(showDate ? work.composed : "").foregroundColor(pal.inkSoft.opacity(0.8))
                     + Text(progress.map { (showDate ? "  " : "") + percentLabel($0) } ?? "")
                        .foregroundColor(pal.accent))
                        .font(.caption2).lineLimit(1)
                }
            }
            .padding(.top, 10)
        }
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())

        if inMyBooks {
            Button { opener.open(work, from: cover.frame) } label: { label }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) { reading.removeFromMyBooks(work.id) } label: {
                        Label("Remove from My Books", systemImage: "minus.circle")
                    }
                }
        } else {
            NavigationLink(value: BookOverview(work)) { label }.buttonStyle(.plain)
        }
    }
}

// First launch: Meditations waits on the desk, with one line on how My Books works.
struct StarterBook: View {
    static let workId = "work.marcus-aurelius.meditations"
    let work: Work?
    let showLibrary: () -> Void
    @EnvironmentObject var opener: BookOpener
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var cover = CoverFrame()

    var body: some View {
        let pal = Palette.forScheme(colorScheme)
        VStack(spacing: 14) {
            if let work {
                Text("Start here.")
                    .font(.system(.title3, design: .serif)).italic()
                    .foregroundColor(pal.inkSoft)
                Button { opener.open(work, from: cover.frame) } label: {
                    BookCoverArt(work: work)
                        .frame(width: hSize == .regular ? 240 : 190)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cover.frame = $0 }
                        .opacity(opener.opening?.work.id == work.id ? 0 : 1)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                Text(work.title)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundColor(pal.ink)
                Text(work.author)
                    .font(.system(.subheadline, design: .serif)).italic()
                    .foregroundColor(pal.inkSoft)
                    .padding(.top, -8)
                Button { opener.open(work, from: cover.frame) } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "book")
                        Text("Begin reading").font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 26).padding(.vertical, 12)
                    .background(Capsule().fill(pal.accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            Text(libraryLine(pal))
                .font(.system(.footnote, design: .serif))
                .foregroundColor(pal.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .environment(\.openURL, OpenURLAction { _ in showLibrary(); return .handled })
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    // "…Find more in the Library." with "Library" tappable.
    private func libraryLine(_ pal: Palette) -> AttributedString {
        var s = AttributedString("Every book you open is kept here. Find more in the ")
        var link = AttributedString("Library")
        link.link = URL(string: "lectio-app:library")
        link.foregroundColor = pal.accent
        link.underlineStyle = .single
        s.append(link)
        s.append(AttributedString("."))
        return s
    }
}

// The most recently opened book, large, with where the reader is and a way back in.
struct FeaturedBook: View {
    let work: Work
    @EnvironmentObject var reading: ReadingState
    @EnvironmentObject var opener: BookOpener
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var cover = CoverFrame()

    var body: some View {
        let pal = Palette.forScheme(colorScheme)
        let st = reading.state(work.id)
        HStack(alignment: .center, spacing: 20) {
            Button { open() } label: {
                BookCoverArt(work: work, progress: st?.progress)
                    .frame(width: hSize == .regular ? 210 : 130)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cover.frame = $0 }
                    .opacity(opener.opening?.work.id == work.id ? 0 : 1)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 6) {
                Text(work.title)
                    .font(.system(size: hSize == .regular ? 34 : 24, weight: .semibold, design: .serif))
                    .foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(work.author)
                    .font(.system(.subheadline, design: .serif)).italic()
                    .foregroundColor(pal.inkSoft)
                if let place = st?.place {
                    Text(place).font(.caption).foregroundColor(pal.inkSoft)
                }
                Button { open() } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "book")
                        Text(st?.segmentId == nil ? "Begin" : "Continue").font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Capsule().fill(pal.accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            Spacer(minLength: 0)
        }
        .contextMenu {
            Button(role: .destructive) { reading.removeFromMyBooks(work.id) } label: {
                Label("Remove from My Books", systemImage: "minus.circle")
            }
        }
    }

    private func open() { opener.open(work, from: cover.frame) }
}

// A fine clothbound cover: dyed book-cloth with depth, a gilt double-rule frame,
// a faint classical emblem, small-caps author, serif title, and a laurel ornament.
// Drawn where a work has no bundled cover image. A nil height fills its container.
struct SpineCard: View {
    let work: Work
    var height: CGFloat? = 234

    private let gilt = Color(hex: 0xC6A867)
    private let cream = Color(hex: 0xEFE6D2)

    var body: some View {
        let cloth = SpineColor.color(for: work.id)
        ZStack {
            // Cloth base with a subtle sheen + vignette for depth.
            cloth
            LinearGradient(
                colors: [Color.white.opacity(0.08), .clear, Color.black.opacity(0.24)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Spine fold along the left edge.
            HStack(spacing: 0) {
                Color.black.opacity(0.20).frame(width: 6)
                Color.white.opacity(0.10).frame(width: 1)
                Spacer()
            }
            // Faint embossed emblem behind the title.
            Image(systemName: emblem)
                .font(.system(size: 88, weight: .light))
                .foregroundColor(gilt.opacity(0.12))
                .offset(y: 4)
            // Gilt double-rule frame.
            RoundedRectangle(cornerRadius: 4).inset(by: 9)
                .stroke(gilt.opacity(0.55), lineWidth: 1)
            RoundedRectangle(cornerRadius: 2).inset(by: 13)
                .stroke(gilt.opacity(0.30), lineWidth: 0.5)

            VStack(spacing: 8) {
                Text(work.author.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(2.5)
                    .foregroundColor(gilt)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Rectangle().fill(gilt.opacity(0.7)).frame(width: 24, height: 1)
                Spacer(minLength: 2)
                Text(work.title)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: height != nil)
                Spacer(minLength: 2)
                HStack(spacing: 3) {
                    Image(systemName: "laurel.leading")
                    Circle().fill(gilt).frame(width: 3, height: 3)
                    Image(systemName: "laurel.trailing")
                }
                .font(.system(size: 13))
                .foregroundColor(gilt.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity, maxHeight: height == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
    }

    private var emblem: String {
        switch work.type {
        case "philosophy": return "building.columns"
        case "epic_poem": return "shield.lefthalf.filled"
        case "religion": return "cross"
        case "politics": return "crown"
        case "drama": return "theatermasks"
        default: return "book.closed"
        }
    }
}
