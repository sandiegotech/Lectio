import SwiftUI
import UIKit

struct LibraryView: View {
    @EnvironmentObject var library: Library
    @EnvironmentObject var saved: SavedStore
    @EnvironmentObject var reading: ReadingState
    @Environment(\.colorScheme) private var colorScheme
    @State private var path = NavigationPath()
    @State private var browseMode: BrowseMode = .collections
    @State private var showSearch = false
    @State private var searchSeed = ""
    @State private var showOnboarding = false
    @AppStorage("showLocked") private var showLocked = false
    @AppStorage("lectio.onboarding.seen.v1") private var onboardingSeen = false
    private var pal: Palette { Palette.forScheme(colorScheme) }

    enum BrowseMode: Hashable { case explore, collections, genres, timeline }

    // In-copyright works never appear on the shelves — they surface only in the timeline's
    // own "still under copyright" section (unlocked there) and in Search.
    private func visible(_ planned: [BookCollection.Planned]?) -> [BookCollection.Planned] {
        (planned ?? []).filter { !$0.isLocked }
    }

    private func bookOverview(shell p: BookCollection.Planned) -> BookOverview {
        BookOverview(title: p.title, author: p.author ?? "", era: p.era ?? "",
                     overview: p.note ?? "", workId: nil, coverPath: p.cover, tradition: p.tradition)
    }

    private var shownCollections: [BookCollection] {
        if browseMode == .genres { return library.collections.filter { $0.isGenre } }
        // Home shelves only (Start here, West, East). Lists like Harvard & Beyond are
        // reachable from a book's "Appears in" chips, not as their own shelves.
        return library.collections.filter { $0.kind == "series" }
    }

    // Shelves, with an umbrella header inserted when the `group` changes (e.g. Religious Texts).
    private enum Row: Identifiable {
        case header(String)
        case shelf(BookCollection)
        var id: String {
            switch self {
            case .header(let g): return "group:" + g
            case .shelf(let c): return c.id
            }
        }
    }
    private var rows: [Row] {
        var result: [Row] = []
        var lastGroup: String?
        for c in shownCollections {
            if let g = c.group, g != lastGroup { result.append(.header(g)) }
            lastGroup = c.group
            result.append(.shelf(c))
        }
        return result
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    browseToggle
                    if browseMode == .explore {
                        ExploreFeed()
                    } else if browseMode == .timeline {
                        timeline
                    } else {
                        continueReadingCard
                        if !saved.collection.isEmpty { myCollectionShelf }
                        ForEach(rows) { row in
                            switch row {
                            case .header(let group):
                                Text(group.uppercased())
                                    .font(.caption).tracking(2.5).foregroundColor(pal.accent)
                                    .padding(.horizontal, 26).padding(.top, 4)
                            case .shelf(let collection):
                                collectionShelf(collection)
                            }
                        }
                    }
                    instituteCredit
                }
                .padding(.top, 8)
                .padding(.bottom, 18)
            }
            .defaultScrollAnchor(ProcessInfo.processInfo.environment["LECTIO_DEBUG_BOTTOM"] != nil ? .bottom : .top)
            .safeAreaInset(edge: .top) { header }
            .background(pal.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Work.self) { work in
                ReaderView(work: work)
            }
            .navigationDestination(for: ReaderRoute.self) { route in
                if let work = library.works.first(where: { $0.id == route.workId }) {
                    ReaderView(work: work, initialTarget: route.target)
                }
            }
            .navigationDestination(for: BookCollection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .navigationDestination(for: OverviewRoute.self) { route in
                OverviewReaderView(eyebrow: route.eyebrow, title: route.title, text: route.text)
            }
            .navigationDestination(for: BookOverview.self) { BookOverviewView(book: $0) }
            .navigationDestination(for: Concept.self) { ConceptDetailView(concept: $0) }
            .navigationDestination(for: WordStudy.self) { WordStudyView(study: $0) }
        }
        .sheet(isPresented: $showSearch) { SearchView(initialQuery: searchSeed) }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(onDone: { onboardingSeen = true })
        }
        .onAppear {
            // First launch: a brief overview of what Lectio is (LECTIO_DEBUG_ONBOARDING forces it).
            if !onboardingSeen || ProcessInfo.processInfo.environment["LECTIO_DEBUG_ONBOARDING"] != nil {
                showOnboarding = true
            }
            // Debug hooks for headless screenshots of the new surfaces.
            if ProcessInfo.processInfo.environment["LECTIO_SHOW_LOCKED"] != nil { showLocked = true }
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_SEED_COLLECTION"] != nil {
                for (t, a) in [("The Iliad","Homer"),("The Analects","Confucius"),("Meditations","Marcus Aurelius")]
                where !saved.isInCollection(t) {
                    saved.toggleCollection(SavedBook(title: t, author: a))
                }
            }
            if let q = ProcessInfo.processInfo.environment["LECTIO_DEBUG_SEARCH"] {
                searchSeed = q; showSearch = true
            }
            // Debug hook: LECTIO_DEBUG_SEED_READING=<workId> seeds a reading position
            // partway into that work, so the Continue-reading card shows (for screenshots).
            if let wid = ProcessInfo.processInfo.environment["LECTIO_DEBUG_SEED_READING"],
               let w = library.works.first(where: { $0.id == wid }),
               let ed = library.edition(w.defaultEditionId) {
                let sec = ed.sections.count > 3 ? ed.sections[3] : ed.sections.first
                reading.savePosition(workId: w.id, editionId: ed.id,
                                     sectionId: sec?.id, segmentId: sec?.segments.first?.id)
            }
            // Debug hook: LECTIO_DEBUG_BOOK=<title> opens that book's overview page.
            if let bt = ProcessInfo.processInfo.environment["LECTIO_DEBUG_BOOK"] {
                if let w = library.works.first(where: { $0.title == bt }) {
                    path.append(BookOverview(title: w.title, author: w.author, era: w.composed,
                                             overview: w.blurb, workId: w.id, coverPath: nil,
                                             tradition: w.tradition))
                } else {
                    for c in library.collections {
                        if let p = (c.planned ?? []).first(where: { $0.title == bt }) {
                            path.append(BookOverview(title: p.title, author: p.author ?? "", era: p.era ?? "",
                                                     overview: p.note ?? "", workId: nil, coverPath: p.cover,
                                                     tradition: p.tradition))
                            break
                        }
                    }
                }
            }
            // Debug hook: LECTIO_OPEN_WORK=<workId> opens straight into the reader.
            if let wid = ProcessInfo.processInfo.environment["LECTIO_OPEN_WORK"],
               let work = library.works.first(where: { $0.id == wid }) {
                path.append(work)
            }
            // Debug hook: LECTIO_DEBUG_STUDY=<workId>|<term> opens the word-study page.
            if let spec = ProcessInfo.processInfo.environment["LECTIO_DEBUG_STUDY"] {
                let parts = spec.split(separator: "|", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    path.append(WordStudy(term: parts[1], workId: parts[0]))
                }
            }
            // Debug hook: LECTIO_DEBUG_CONCEPT=<conceptId> opens that concept's page.
            if let cid = ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONCEPT"],
               let c = library.concept(id: cid) {
                path.append(c)
            }
            // Debug hooks: open the library on a given axis (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_EXPLORE"] != nil { browseMode = .explore }
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_GENRES"] != nil { browseMode = .genres }
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_TIMELINE"] != nil { browseMode = .timeline }
            // Debug hook: LECTIO_DEBUG_COLLECTION=<id> opens a collection's page (for screenshots).
            if let cid = ProcessInfo.processInfo.environment["LECTIO_DEBUG_COLLECTION"],
               let c = library.collections.first(where: { $0.id == cid }) {
                path.append(c)
                if ProcessInfo.processInfo.environment["LECTIO_DEBUG_OVERVIEW"] != nil,
                   let intro = c.introduction {
                    path.append(OverviewRoute(eyebrow: "An Introduction", title: c.title, text: intro))
                }
            }
        }
    }

    // MARK: continue reading — one tap back into the book you were last in.

    @ViewBuilder
    private var continueReadingCard: some View {
        if let wid = reading.mostRecentWorkId,
           let work = library.works.first(where: { $0.id == wid }) {
            NavigationLink(value: work) {
                HStack(spacing: 14) {
                    continueThumb(work)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CONTINUE READING")
                            .font(.caption2.weight(.semibold)).tracking(2)
                            .foregroundColor(pal.accent)
                        Text(work.title)
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundColor(pal.ink)
                        Text(continueSubtitle(work))
                            .font(.caption).foregroundColor(pal.inkSoft).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2).foregroundColor(pal.accent)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(pal.rail))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(pal.rule))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 26)
        }
    }

    @ViewBuilder
    private func continueThumb(_ w: Work) -> some View {
        if let url = library.coverURL(w.id), let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: 44, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
        } else {
            SpineCard(work: w, height: 64).frame(width: 44)
        }
    }

    // "Book IV · 17% through · Lectio Edition" — where the reader left off.
    private func continueSubtitle(_ work: Work) -> String {
        let st = reading.state(work.id)
        guard let ed = library.edition(st?.editionId ?? work.defaultEditionId) else { return work.author }
        var parts: [String] = []
        if let sid = st?.sectionId, let i = ed.sections.firstIndex(where: { $0.id == sid }) {
            parts.append(ed.sections[i].label)
            if ed.sections.count > 1 {
                parts.append("\(Int((Double(i + 1) / Double(ed.sections.count) * 100).rounded()))% through")
            }
        }
        switch ed.kind {
        case "modern": parts.append("Lectio Edition")
        case "original": parts.append("Original")
        default:
            if let t = ed.translator {
                parts.append(ed.publishedYear.map { "\(t) · \($0)" } ?? t)
            }
        }
        return parts.isEmpty ? work.author : parts.joined(separator: "  ·  ")
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

    // Ways to browse: Explore (a famous-line doorway), by collection (which set),
    // by genre (which section), or by timeline (earliest book to latest).
    private var browseToggle: some View {
        Picker("Browse", selection: $browseMode) {
            Text("Explore").tag(BrowseMode.explore)
            Text("Collections").tag(BrowseMode.collections)
            Text("Genres").tag(BrowseMode.genres)
            Text("Timeline").tag(BrowseMode.timeline)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 26)
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

    // MARK: collection shelves — the library browses by collection (Harvard Classics,
    // Epics, …). Each is a titled row of covers standing on a slim shelf, gallery-like.

    private let bookHeights: [CGFloat] = [238, 252, 232, 246, 244, 234]

    private func collectionShelf(_ collection: BookCollection) -> some View {
        let works = library.works(in: collection)
        let shells = visible(collection.planned)
        return VStack(alignment: .leading, spacing: 8) {
            NavigationLink(value: collection) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(collection.title)
                            .font(.system(.title3, design: .serif)).foregroundColor(pal.ink)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold)).foregroundColor(pal.inkSoft)
                    }
                    Text("\(collection.curator)  ·  \(works.count + shells.count) works")
                        .font(.caption).foregroundColor(pal.inkSoft)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 26)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: 26) {
                    ForEach(Array(works.enumerated()), id: \.element.id) { idx, work in
                        NavigationLink(value: work) {
                            coverWithReflection(work, height: bookHeights[idx % bookHeights.count])
                        }
                        .buttonStyle(.plain)
                        .frame(width: 150)
                    }
                    // Shells: planned works not yet ingested — tap to learn more, captioned below.
                    ForEach(Array(shells.enumerated()), id: \.offset) { i, p in
                        NavigationLink(value: bookOverview(shell: p)) {
                            VStack(spacing: 0) {
                                plannedCoverArt(p, in: collection, height: bookHeights[(works.count + i) % bookHeights.count])
                                    .opacity(0.92)
                                Text("Coming soon")
                                    .font(.system(size: 10, weight: .medium)).tracking(0.4)
                                    .foregroundColor(pal.inkSoft)
                                    .frame(height: 30, alignment: .center)   // matches the reflection band so cover bottoms align
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 150)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 8)
            }
            shelfLine
        }
    }

    // Dim an in-copyright shell and stamp a small lock + the year it opens.
    @ViewBuilder
    private func lockable(_ p: BookCollection.Planned, _ content: some View) -> some View {
        if p.isLocked {
            content
                .opacity(0.5)
                .overlay(alignment: .top) {
                    if let y = p.opens {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill").font(.system(size: 8))
                            Text("Opens \(String(y))").font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(pal.ink)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(pal.paper.opacity(0.92)))
                        .overlay(Capsule().stroke(pal.rule))
                        .padding(.top, 10)
                    }
                }
        } else {
            content
        }
    }

    // The reader's checked-out books — a personal shelf pinned at the top of Collections.
    private var myCollectionShelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: NotesView()) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text("My Collection").font(.system(.title3, design: .serif)).foregroundColor(pal.ink)
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundColor(pal.inkSoft)
                    }
                    Text("Checked out  ·  \(saved.collection.count) \(saved.collection.count == 1 ? "book" : "books")")
                        .font(.caption).foregroundColor(pal.inkSoft)
                }
            }
            .buttonStyle(.plain).padding(.horizontal, 26)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: 26) {
                    ForEach(Array(saved.collection.enumerated()), id: \.element.id) { idx, b in
                        if let ov = library.bookOverview(title: b.title) {
                            // A checked-out book opens straight into the reader (resuming
                            // your place); the overview stays one long-press away.
                            if let wid = ov.workId,
                               let w = library.works.first(where: { $0.id == wid }) {
                                NavigationLink(value: w) {
                                    myCollectionCover(b, height: bookHeights[idx % bookHeights.count])
                                }
                                .buttonStyle(.plain).frame(width: 150)
                                .contextMenu {
                                    Button { path.append(ov) } label: {
                                        Label("About this book", systemImage: "info.circle")
                                    }
                                }
                            } else {
                                NavigationLink(value: ov) {
                                    myCollectionCover(b, height: bookHeights[idx % bookHeights.count])
                                }
                                .buttonStyle(.plain).frame(width: 150)
                            }
                        }
                    }
                }
                .padding(.horizontal, 26).padding(.top, 8)
            }
            shelfLine
        }
    }

    @ViewBuilder
    private func myCollectionCover(_ b: SavedBook, height: CGFloat) -> some View {
        let ov = library.bookOverview(title: b.title)
        if let id = ov?.workId, let url = library.coverURL(id), let img = UIImage(contentsOfFile: url.path) {
            coverThumb(img, height: height)
        } else if let cp = ov?.coverPath, let url = library.plannedCoverURL(cp), let img = UIImage(contentsOfFile: url.path) {
            coverThumb(img, height: height)
        } else {
            PlaceholderCard(title: b.title, author: b.author, pal: pal, tradition: ov?.tradition ?? "West", height: height)
        }
    }

    private func coverThumb(_ img: UIImage, height: CGFloat) -> some View {
        Image(uiImage: img).resizable().scaledToFill()
            .frame(width: 150, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
    }

    private func coverWithReflection(_ work: Work, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            coverArt(work, height: height)
            coverArt(work, height: height)
                .scaleEffect(y: -1, anchor: .center)
                .frame(height: 30, alignment: .top)
                .clipped()
                .opacity(0.16)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                .allowsHitTesting(false)
        }
    }

    private func plannedCoverWithReflection(_ planned: BookCollection.Planned, in collection: BookCollection, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            plannedCoverArt(planned, in: collection, height: height)
            plannedCoverArt(planned, in: collection, height: height)
                .scaleEffect(y: -1, anchor: .center)
                .frame(height: 30, alignment: .top)
                .clipped()
                .opacity(0.16)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                .allowsHitTesting(false)
        }
    }

    // The bundled cover image if there is one; otherwise the drawn clothbound card.
    @ViewBuilder
    private func coverArt(_ work: Work, height: CGFloat) -> some View {
        if let url = library.coverURL(work.id), let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
        } else {
            SpineCard(work: work, height: height)
        }
    }

    @ViewBuilder
    private func plannedCoverArt(_ planned: BookCollection.Planned, in collection: BookCollection, height: CGFloat) -> some View {
        if let url = library.plannedCoverURL(previewCoverPath(for: planned, in: collection)), let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
        } else {
            PlaceholderCard(title: planned.title, author: planned.author, pal: pal, tradition: planned.tradition, height: height)
        }
    }

    private func previewCoverPath(for planned: BookCollection.Planned, in collection: BookCollection) -> String? {
        // Always the Lectio (western) cover, for a consistent theme across every shelf —
        // including Harvard Classics, where we used to swap in the red Harvard-edition cover.
        planned.cover
    }

    // MARK: timeline — every book, earliest to latest, grouped by era

    private struct TimelineBook: Identifiable {
        let id: String
        let title: String
        let author: String
        let era: String
        let note: String
        let work: Work?
        let coverName: String?
        let tradition: String?
        let opens: Int?
        var isLocked: Bool { opens != nil }
    }

    // All books once (real works + unique shells), sorted earliest → latest.
    // In-copyright shells are omitted unless the reader has opted to show them.
    private var timelineBooks: [TimelineBook] {
        var out: [TimelineBook] = []
        var seen = Set<String>()
        for w in library.works {
            seen.insert(w.title)
            out.append(TimelineBook(id: "w:" + w.id, title: w.title, author: w.author,
                                    era: w.composed, note: w.blurb, work: w, coverName: nil,
                                    tradition: w.tradition, opens: nil))
        }
        for c in library.collections {
            for p in c.planned ?? [] where !p.isLocked && !seen.contains(p.title) {
                seen.insert(p.title)
                out.append(TimelineBook(id: "p:" + p.title, title: p.title, author: p.author ?? "",
                                        era: p.era ?? "", note: p.note ?? "", work: nil, coverName: p.cover,
                                        tradition: p.tradition, opens: nil))
            }
        }
        return out.sorted { sortYear($0.era) < sortYear($1.era) }
    }

    // The in-copyright works, shown only in the timeline's own unlockable section.
    private var lockedTimelineBooks: [TimelineBook] {
        var out: [TimelineBook] = []
        var seen = Set<String>()
        for c in library.collections {
            for p in c.planned ?? [] where p.isLocked && !seen.contains(p.title) {
                seen.insert(p.title)
                out.append(TimelineBook(id: "lk:" + p.title, title: p.title, author: p.author ?? "",
                                        era: p.era ?? "", note: p.note ?? "", work: nil, coverName: p.cover,
                                        tradition: p.tradition, opens: p.opens))
            }
        }
        return out.sorted { sortYear($0.era) < sortYear($1.era) }
    }

    // Rough sortable year from an era string ("c. 800–200 BCE", "1776", "8th–9th c."…).
    private func sortYear(_ era: String) -> Int {
        let s = era.lowercased()
        if s.hasPrefix("ancient") { return -2000 }
        guard let n = firstInt(s) else { return 3000 }
        let after = s[n.end...]
        let century = after.hasPrefix("st") || after.hasPrefix("nd")
                   || after.hasPrefix("rd") || after.hasPrefix("th")
        let bce = s.contains("bce") || s.contains(" bc")
        if century { return bce ? -(n.value * 100) : (n.value - 1) * 100 }
        return bce ? -n.value : n.value
    }

    private func firstInt(_ s: String) -> (value: Int, end: String.Index)? {
        guard let start = s.firstIndex(where: { $0.isNumber }) else { return nil }
        var j = start, val = 0
        while j < s.endIndex, let d = s[j].wholeNumberValue { val = val * 10 + d; j = s.index(after: j) }
        return (val, j)
    }

    private func epoch(_ year: Int) -> String {
        switch year {
        case ..<500: return "The Ancient World"
        case 500..<1450: return "The Middle Ages"
        case 1450..<1660: return "Renaissance & Reformation"
        case 1660..<1800: return "The Enlightenment"
        default: return "The Modern Age"
        }
    }

    private var timeline: some View {
        // Group the sorted books into contiguous era buckets.
        var groups: [(String, [TimelineBook])] = []
        for b in timelineBooks {
            let e = epoch(sortYear(b.era))
            if groups.last?.0 == e { groups[groups.count - 1].1.append(b) }
            else { groups.append((e, [b])) }
        }
        return LazyVStack(alignment: .leading, spacing: 10, pinnedViews: []) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, g in
                Text(g.0.uppercased())
                    .font(.caption).tracking(2).foregroundColor(pal.accent)
                    .padding(.horizontal, 26).padding(.top, 14)
                ForEach(g.1) { timelineRow($0) }
            }
            pdHorizonFooter
            lockedSection
        }
    }

    // The unlock control lives here, at the foot of the timeline: reveal the in-copyright
    // works right where the public-domain horizon explains why they aren't yet readable.
    @ViewBuilder
    private var lockedSection: some View {
        if lockedTimelineBooks.isEmpty {
            EmptyView()
        } else if showLocked {
            HStack {
                Text("STILL UNDER COPYRIGHT").font(.caption).tracking(2).foregroundColor(pal.accent)
                Spacer()
                Button { withAnimation { showLocked = false } } label: {
                    Text("Hide").font(.caption.weight(.medium)).foregroundColor(pal.inkSoft)
                }
            }
            .padding(.horizontal, 26).padding(.top, 2)
            Text("Not yet free to read — listed with the year each enters the public domain.")
                .font(.caption2).foregroundColor(pal.inkSoft)
                .padding(.horizontal, 26).padding(.bottom, 2)
            ForEach(lockedTimelineBooks) { timelineRow($0) }
            Color.clear.frame(height: 24)
        } else {
            Button { withAnimation { showLocked = true } } label: {
                HStack(spacing: 7) {
                    Image(systemName: "lock.fill").font(.caption2)
                    Text("Show \(lockedTimelineBooks.count) works still under copyright")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(pal.accent)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(Capsule().fill(pal.rail))
                .overlay(Capsule().stroke(pal.rule))
            }
            .padding(.horizontal, 26).padding(.bottom, 24)
        }
    }

    // The most recent year now in the U.S. public domain (95 years after publication).
    private var pdCutoffYear: Int {
        Calendar.current.component(.year, from: Date()) - 96
    }

    // A quiet endnote explaining why the timeline thins toward the present.
    private var pdHorizonFooter: some View {
        VStack(alignment: .leading, spacing: 9) {
            Rectangle().fill(pal.rule).frame(height: 1)
                .padding(.horizontal, 26).padding(.top, 18).padding(.bottom, 2)
            HStack(spacing: 7) {
                Image(systemName: "lock.open").font(.caption2.weight(.semibold))
                Text("THE PUBLIC-DOMAIN HORIZON").font(.caption2).tracking(2)
            }
            .foregroundColor(pal.accent)
            .padding(.horizontal, 26)
            Text("In the U.S. a work enters the public domain 95 years after it is published, so everything first published in \(pdCutoffYear) or earlier is free to read — and every January 1st another year joins. That is why the shelf thins toward the present.")
                .font(.system(size: 14, design: .serif)).lineSpacing(3)
                .foregroundColor(pal.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 26)
            Text("Lectio reads everything already public, and publishes its own Modern Edition wherever a work is free but only its translations are locked. Works still under copyright are listed but not yet readable — they open to everyone the moment their term ends.")
                .font(.system(size: 13, design: .serif)).lineSpacing(3)
                .foregroundColor(pal.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 26)
        }
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func timelineRow(_ b: TimelineBook) -> some View {
        let row = HStack(alignment: .top, spacing: 12) {
            timelineThumb(b).frame(width: 44, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(b.title).font(.system(.subheadline, design: .serif).weight(.medium))
                        .foregroundColor(pal.ink)
                    if !b.era.isEmpty {
                        Text(b.era).font(.caption2).foregroundColor(pal.accent.opacity(0.85))
                    }
                }
                if !b.author.isEmpty {
                    Text(b.author).font(.caption).foregroundColor(pal.inkSoft)
                }
                if let y = b.opens {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill").font(.system(size: 8))
                        Text("Enters the public domain in \(String(y))").font(.caption2)
                    }
                    .foregroundColor(pal.inkSoft)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: b.work != nil ? "checkmark.circle.fill" : "hourglass")
                            .font(.system(size: 9))
                        Text(b.work != nil ? "In the library" : "Coming soon").font(.caption2.weight(.medium))
                    }
                    .foregroundColor(b.work != nil ? pal.accent : pal.inkSoft)
                    if !b.note.isEmpty {
                        Text(b.note).font(.caption2).foregroundColor(pal.inkSoft.opacity(0.9))
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 0)
            if !b.isLocked {
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                    .foregroundColor(pal.inkSoft.opacity(0.55))
            }
        }
        .padding(.horizontal, 26)
        .opacity(b.isLocked ? 0.5 : 1)
        .contentShape(Rectangle())
        if b.isLocked {
            row
        } else {
            NavigationLink(value: BookOverview(title: b.title, author: b.author, era: b.era,
                                               overview: b.note, workId: b.work?.id, coverPath: b.coverName,
                                               tradition: b.tradition)) {
                row
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func timelineThumb(_ b: TimelineBook) -> some View {
        if let w = b.work, let url = library.coverURL(w.id), let img = UIImage(contentsOfFile: url.path) {
            thumbImage(img)
        } else if let cn = b.coverName, let url = library.plannedCoverURL(cn), let img = UIImage(contentsOfFile: url.path) {
            thumbImage(img)
        } else if let w = b.work {
            SpineCard(work: w, height: 64)
        } else {
            let isEast = b.tradition == "East"
            let fill = isEast ? Color(hex: 0x071118).opacity(0.96) : pal.paper.opacity(0.5)
            let stroke = isEast ? Color(hex: 0xB58A3B).opacity(0.72) : pal.rule
            let icon = isEast ? Color(hex: 0xD3B06A).opacity(0.68) : pal.inkSoft.opacity(0.5)
            RoundedRectangle(cornerRadius: 4).fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(stroke, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                .overlay(Image(systemName: "hourglass").font(.system(size: 12))
                    .foregroundColor(icon))
        }
    }

    private func thumbImage(_ img: UIImage) -> some View {
        Image(uiImage: img).resizable().scaledToFill()
            .frame(width: 44, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
    }

    private var shelfLine: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [pal.inkSoft.opacity(0.55), pal.inkSoft.opacity(0.12)],
                startPoint: .top, endPoint: .bottom))
            .frame(height: 2)
            .shadow(color: .black.opacity(0.14), radius: 4, y: 3)
            .padding(.horizontal, 24)
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

// A shell on the shelf — a planned work, drawn as a faint "coming soon" book.
struct PlaceholderCard: View {
    let title: String
    let author: String?
    let pal: Palette
    let tradition: String?
    var height: CGFloat = 234

    private var isEast: Bool { tradition == "East" }
    private var fill: Color { isEast ? Color(hex: 0x071118).opacity(0.96) : pal.paper.opacity(0.4) }
    private var stroke: Color { isEast ? Color(hex: 0xB58A3B).opacity(0.72) : pal.rule }
    private var mainText: Color { isEast ? Color(hex: 0xD3B06A) : pal.inkSoft }
    private var softText: Color { isEast ? Color(hex: 0xC9B98A) : pal.inkSoft }

    var body: some View {
        VStack(spacing: 7) {
            Spacer(minLength: 0)
            Image(systemName: "hourglass")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(softText.opacity(0.55))
            if let author, !author.isEmpty {
                Text(author.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .serif))
                    .tracking(1.6)
                    .foregroundColor(softText.opacity(0.72))
                    .multilineTextAlignment(.center).lineLimit(2)
            }
            Text(title)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundColor(mainText)
                .multilineTextAlignment(.center).lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text("Coming soon")
                .font(.caption2).tracking(0.5)
                .foregroundColor(softText.opacity(0.6))
        }
        .padding(.horizontal, 14).padding(.vertical, 16)
        .frame(width: 150, height: height)
        .background(RoundedRectangle(cornerRadius: 6).fill(fill))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(stroke, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }
}

// A fine clothbound cover: dyed book-cloth with depth, a gilt double-rule frame,
// a faint classical emblem, small-caps author, serif title, and a laurel ornament.
struct SpineCard: View {
    let work: Work
    var height: CGFloat = 234

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
                    .fixedSize(horizontal: false, vertical: true)
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
        .frame(maxWidth: .infinity)
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
