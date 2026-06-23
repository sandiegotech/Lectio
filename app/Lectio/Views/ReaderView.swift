import SwiftUI

// Where to land when a book is opened from the collection.
enum ReaderTarget: Hashable {
    case segment(String)   // a saved highlight's segment
    case word(String)      // a saved word — jump to its first occurrence
}

// A navigation route that opens a work at a specific place.
struct ReaderRoute: Hashable {
    let workId: String
    let target: ReaderTarget
}

struct ReaderView: View {
    let work: Work
    var initialTarget: ReaderTarget? = nil
    @EnvironmentObject var library: Library
    @EnvironmentObject var dictionary: WordDictionary
    @EnvironmentObject var saved: SavedStore
    @EnvironmentObject var reading: ReadingState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var explore = false
    @State private var showContents = false
    @State private var expandedBooks: Set<String> = []
    @State private var currentBookIndex = 0
    @State private var currentEditionId: String?
    @State private var scrollTarget: String?
    @State private var showProvenance = false
    @State private var introExpanded = true
    @State private var topSegmentId: String?
    @State private var didRestore = false
    @State private var animateScroll = true
    @State private var wordPopup: WordPopup?
    @State private var focusWord: String?
    @State private var selSegmentId: String?
    @State private var selRange: ClosedRange<Int>?
    @State private var selPopup: SelPopup?
    @State private var showMarksSheet = false
    @State private var compare = false
    @State private var compareEditionId: String?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize

    private var pal: Palette { Palette.forScheme(colorScheme) }

    // A word lookup popup, anchored near the tapped word.
    struct WordPopup { var term: String; var def: String?; var point: CGPoint }
    // A "save this highlight" popup, anchored near the end of a selection drag.
    struct SelPopup { var segmentId: String; var range: ClosedRange<Int>; var text: String; var point: CGPoint }

    // Ordered: Lectio Modern Edition first, then translations latest-first, original last.
    private var editions: [Edition] {
        func rank(_ e: Edition) -> Int {
            switch e.kind {
            case "modern": return 0
            case "original": return 2
            default: return 1
            }
        }
        return work.editionIds.compactMap { library.editions[$0] }.sorted { a, b in
            if rank(a) != rank(b) { return rank(a) < rank(b) }
            return (a.publishedYear ?? 0) > (b.publishedYear ?? 0)
        }
    }

    private var currentEdition: Edition? {
        if let id = currentEditionId, let e = library.editions[id] { return e }
        return library.editions[work.defaultEditionId] ?? editions.first
    }

    // The edition shown alongside in compare mode (any edition other than the one being read).
    private var compareEdition: Edition? {
        if let id = compareEditionId, let e = library.editions[id], id != currentEdition?.id { return e }
        return editions.first { $0.id != currentEdition?.id }
    }

    private var currentSection: Section? {
        guard let ed = currentEdition, !ed.sections.isEmpty else { return nil }
        return ed.sections.indices.contains(currentBookIndex)
            ? ed.sections[currentBookIndex] : ed.sections.first
    }

    private var progress: Double {
        guard let ed = currentEdition, !ed.sections.isEmpty else { return 0 }
        return Double(currentBookIndex + 1) / Double(ed.sections.count)
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                Divider().overlay(pal.rule)
                GeometryReader { rgeo in
                    ZStack(alignment: .top) {
                        if let ed = currentEdition {
                            HStack(alignment: .top, spacing: 0) {
                                readingColumn(ed)
                                if compare, hSize == .regular, let cmp = compareEdition {
                                    Divider().overlay(pal.rule)
                                    compareColumn(cmp)
                                        .frame(width: geo.size.width * 0.44)
                                        .background(pal.paper)
                                        .transition(.move(edge: .trailing))
                                } else if explore && hSize == .regular {
                                    MarginRail(
                                        work: work, pal: pal,
                                        onJump: jumpToSegment,
                                        onWordJump: jumpToWord
                                    )
                                    .frame(width: max(240, geo.size.width * 0.30))
                                    .background(pal.rail)
                                    .transition(.move(edge: .trailing))
                                }
                            }
                        } else {
                            Text("No edition available.").foregroundColor(pal.inkSoft)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        // Scrim that dismisses an open popup on a tap anywhere else.
                        if wordPopup != nil || selPopup != nil {
                            Color.black.opacity(0.001)
                                .onTapGesture { dismissPopups() }
                        }
                        if let wp = wordPopup {
                            WordCard(term: wp.term, definition: wp.def, workTitle: work.title,
                                     workId: work.id, pal: pal, onClose: dismissPopups)
                                .position(popupPosition(wp.point, in: rgeo.size, card: CGSize(width: 260, height: 150)))
                        }
                        if let sp = selPopup {
                            selectionSaveCard(sp)
                                .position(popupPosition(sp.point, in: rgeo.size, card: CGSize(width: 180, height: 48)))
                        }
                    }
                    .coordinateSpace(name: "reader")
                }
            }
            .background(pal.paper)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showContents) { contentsSheet }
        .sheet(isPresented: $showProvenance) {
            if let ed = currentEdition {
                ProvenanceSheet(edition: ed, workTitle: work.title, pal: pal)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showMarksSheet) {
            MarginRail(
                work: work, pal: pal,
                onJump: { id in showMarksSheet = false; jumpToSegment(id) },
                onWordJump: { term in showMarksSheet = false; jumpToWord(term) }
            )
            .background(pal.paper)
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            if currentEditionId == nil { currentEditionId = work.defaultEditionId }
            // Resume where the reader left off, and show the intro expanded only the first time.
            if !didRestore {
                didRestore = true
                let st = reading.state(work.id)
                if let eid = st?.editionId, library.editions[eid] != nil { currentEditionId = eid }
                introExpanded = !reading.introSeen(work.id)
                reading.markIntroSeen(work.id)
                switch initialTarget {
                case .segment(let sid):
                    restorePosition(anchor: sid)
                case .word(let term):
                    focusWord = WordDictionary.normalize(term)
                    if let seg = firstSegment(containing: term) { restorePosition(anchor: seg) }
                case nil:
                    if let anchor = st?.segmentId ?? st?.sectionId { restorePosition(anchor: anchor) }
                }
            }
            // Debug hook: LECTIO_DEBUG_EDITION=<editionId> opens a specific edition.
            if let ed = ProcessInfo.processInfo.environment["LECTIO_DEBUG_EDITION"], !ed.isEmpty {
                currentEditionId = ed
            }
            // Debug hook: LECTIO_DEBUG_SELECT=<word> shows the word popup (for screenshots).
            if let dbg = ProcessInfo.processInfo.environment["LECTIO_DEBUG_SELECT"], !dbg.isEmpty {
                let w = WordDictionary.normalize(dbg)
                wordPopup = WordPopup(term: w, def: dictionary.define(w), point: CGPoint(x: 240, y: 360))
            }
            // Debug hook: LECTIO_DEBUG_CONTEXT shows the context rail (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONTEXT"] != nil {
                explore = true
            }
            // Debug hook: LECTIO_DEBUG_COMPARE turns on side-by-side compare (for screenshots).
            if let c = ProcessInfo.processInfo.environment["LECTIO_DEBUG_COMPARE"] {
                compare = true
                if !c.isEmpty { compareEditionId = c }
                else { compareEditionId = editions.first { $0.id != currentEdition?.id }?.id }
            }
            // Debug hook: LECTIO_DEBUG_PROVENANCE opens the provenance sheet (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_PROVENANCE"] != nil {
                showProvenance = true
            }
            // Debug hook: LECTIO_DEBUG_CONTENTS opens the contents with book 1 expanded.
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONTENTS"] != nil {
                showContents = true
                if let first = currentEdition?.sections.first { expandedBooks = [first.id] }
            }
        }
        .onDisappear { persist() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { persist() } }
    }

    private func persist() {
        guard didRestore else { return }
        reading.savePosition(workId: work.id,
                             editionId: currentEditionId,
                             sectionId: currentSection?.id,
                             segmentId: topSegmentId)
    }

    private func sectionIndex(containing anchorId: String) -> Int? {
        currentEdition?.sections.firstIndex { sec in
            anchorId == sec.id || anchorId.hasPrefix(sec.id + ".")
        }
    }

    private func restorePosition(anchor: String) {
        if let idx = sectionIndex(containing: anchor) { currentBookIndex = idx }
        animateScroll = false
        DispatchQueue.main.async { scrollTarget = anchor }
    }

    private func jumpToSegment(_ segmentId: String) {
        if let idx = sectionIndex(containing: segmentId) { currentBookIndex = idx }
        scrollTarget = segmentId
    }

    private var savedWordSet: Set<String> {
        Set(saved.words(forWork: work.id).map { WordDictionary.normalize($0.term) })
    }

    private func firstSegment(containing term: String) -> String? {
        let needle = term.lowercased()
        for sec in currentEdition?.sections ?? [] {
            for seg in sec.segments where seg.text.lowercased().contains(needle) {
                return seg.id
            }
        }
        return nil
    }

    // Jump to the first place a saved word appears in the open edition and light it up.
    private func jumpToWord(_ term: String) {
        focusWord = WordDictionary.normalize(term)
        if let seg = firstSegment(containing: term) { jumpToSegment(seg) }
    }

    // MARK: header (small, always present)

    private var header: some View {
        HStack(spacing: 14) {
            iconButton("chevron.left") { dismiss() }
            editionMenu
            Spacer()
            iconButton("list.bullet") { showContents = true }
            bookmarkButton
            iconButton("info.circle") { showProvenance = true }
            if hSize == .regular, editions.count > 1 { compareButton }
            contextButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(pal.paper)
    }

    // Side-by-side translation compare (iPad). Reads the same book in two editions at once,
    // following you book-to-book as you scroll the main column.
    private var compareButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                compare.toggle()
                if compare {
                    explore = false
                    if compareEditionId == nil || compareEditionId == currentEdition?.id {
                        compareEditionId = editions.first { $0.id != currentEdition?.id }?.id
                    }
                }
            }
        } label: {
            Image(systemName: compare ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                .font(.body.weight(.medium))
                .foregroundColor(compare ? pal.accent : pal.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private var bookmarkButton: some View {
        let bm = reading.bookmark(work.id)
        return Button { bookmarkAction() } label: {
            Image(systemName: bm != nil ? "bookmark.fill" : "bookmark")
                .font(.body.weight(.medium))
                .foregroundColor(bm != nil ? pal.accent : pal.inkSoft)
        }
        .buttonStyle(.plain)
    }

    // One bookmark per book. Press: create if none; otherwise go to it — unless you're
    // already on its page, in which case clear it (so the same button can move it).
    private func bookmarkAction() {
        guard let bm = reading.bookmark(work.id) else {
            reading.setBookmark(work.id, segmentId: topSegmentId)
            return
        }
        if sectionIndex(containing: bm) == currentBookIndex {
            reading.setBookmark(work.id, segmentId: nil)
        } else {
            jumpToSegment(bm)
        }
    }

    private var contextButton: some View {
        let active = hSize == .regular && explore
        return Button {
            if hSize == .regular {
                withAnimation(.easeInOut(duration: 0.2)) { explore.toggle(); if explore { compare = false } }
            } else {
                showMarksSheet = true     // iPhone: marks open as a bottom sheet
            }
        } label: {
            Image(systemName: active ? "lightbulb.circle.fill" : "lightbulb.circle")
                .font(.body.weight(.medium))
                .foregroundColor(active ? pal.accent : pal.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private var editionMenu: some View {
        Menu {
            Picker("Edition", selection: editionSelection) {
                ForEach(editions) { ed in
                    Text(editionLabel(ed)).tag(ed.id)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(work.title).font(.subheadline.weight(.semibold)).foregroundColor(pal.ink)
                Text("·").foregroundColor(pal.inkSoft)
                Text(currentEdition.map(editionLabel) ?? work.author)
                    .font(.caption).foregroundColor(pal.accent).lineLimit(1)
                Image(systemName: "chevron.down").font(.caption2).foregroundColor(pal.accent)
            }
        }
    }

    private var editionSelection: Binding<String> {
        Binding(
            get: { currentEdition?.id ?? work.defaultEditionId },
            set: { switchEdition(to: $0) }
        )
    }

    private func editionLabel(_ ed: Edition) -> String {
        switch ed.kind {
        case "modern":
            if let v = ed.provenance.vintage { return "Lectio Edition · \(v)" }
            return "Lectio Edition"
        case "original": return "Original · \(languageName(ed.language))"
        default:
            let year = ed.publishedYear.map { " · \($0)" } ?? ""
            return "\(ed.translator ?? "Unknown")\(year)"
        }
    }

    private func languageName(_ code: String) -> String {
        switch code {
        case "grc", "el": return "Greek"
        case "la": return "Latin"
        default: return code.uppercased()
        }
    }

    private func iconButton(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.body.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundColor(pal.inkSoft)
    }

    // MARK: reading column (whole book, continuous scroll)

    private enum Row: Identifiable {
        case header(Section)
        case segment(Segment)
        var id: String {
            switch self {
            case .header(let s): return "h:" + s.id
            case .segment(let seg): return seg.id
            }
        }
    }

    private func rows(_ ed: Edition) -> [Row] {
        var result: [Row] = []
        for section in ed.sections {
            result.append(.header(section))
            for segment in section.segments { result.append(.segment(segment)) }
        }
        return result
    }

    private func readingColumn(_ ed: Edition) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if let intro = ed.introduction, !intro.isEmpty {
                        introBlock(intro)
                    }
                    ForEach(rows(ed)) { row in
                        switch row {
                        case .header(let section):
                            sectionHeader(section)
                                .id(section.id)
                                .contentShape(Rectangle())
                                .onTapGesture { backgroundTap() }
                                .onAppear {
                                    if let idx = ed.sections.firstIndex(where: { $0.id == section.id }) {
                                        currentBookIndex = idx
                                    }
                                }
                        case .segment(let segment):
                            WordFlowText(
                                text: segment.text, pal: pal,
                                definedWord: wordPopup?.term,
                                focusWord: focusWord,
                                savedWords: savedWordSet,
                                savedRanges: saved.ranges(forSegment: segment.id),
                                activeRange: selSegmentId == segment.id ? selRange : nil,
                                onWord: { word, point in showWord(word, at: point) },
                                onSelectCommit: { range, text, point in
                                    selSegmentId = segment.id
                                    selRange = range
                                    selPopup = SelPopup(segmentId: segment.id, range: range,
                                                        text: text, point: point)
                                }
                            )
                            .overlay(alignment: .topLeading) {
                                if reading.bookmark(work.id) == segment.id {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 15)).foregroundColor(pal.gold)
                                        .offset(x: -26, y: -2)
                                }
                            }
                            .onAppear { topSegmentId = segment.id }
                        }
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                if animateScroll {
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                } else {
                    proxy.scrollTo(target, anchor: .top)
                    animateScroll = true
                }
            }
            .onChange(of: currentEditionId) { oldValue, _ in
                // Stay on the same book when the user switches translation — but not on
                // the initial nil -> default assignment, which would scroll past the intro.
                guard oldValue != nil,
                      let ed = currentEdition, ed.sections.indices.contains(currentBookIndex) else { return }
                let id = ed.sections[currentBookIndex].id
                DispatchQueue.main.async { proxy.scrollTo(id, anchor: .top) }
            }
        }
    }

    // MARK: compare column — the same book in a second edition, book-level synced

    @ViewBuilder
    private func compareColumn(_ ed: Edition) -> some View {
        VStack(spacing: 0) {
            compareHeader(ed)
            Divider().overlay(pal.rule)
            if ed.sections.indices.contains(currentBookIndex) {
                let sec = ed.sections[currentBookIndex]
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader(sec)
                        ForEach(sec.segments) { seg in
                            Text(seg.text)
                                .font(.system(size: 17, design: .serif))
                                .lineSpacing(6)
                                .foregroundColor(pal.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24).padding(.vertical, 20)
                }
                .id(sec.id)   // reset scroll to top when the synced book changes
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed").font(.title2).foregroundColor(pal.inkSoft.opacity(0.5))
                    Text("This book isn't in the \(editionLabel(ed)) yet.")
                        .font(.callout).foregroundColor(pal.inkSoft).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            }
        }
    }

    private func compareHeader(_ ed: Edition) -> some View {
        HStack(spacing: 8) {
            Text("COMPARE").font(.caption2).tracking(2).foregroundColor(pal.inkSoft)
            Spacer()
            Menu {
                Picker("Compare with", selection: compareSelection) {
                    ForEach(editions.filter { $0.id != currentEdition?.id }) { e in
                        Text(editionLabel(e)).tag(e.id)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(editionLabel(ed)).font(.caption.weight(.medium))
                        .foregroundColor(pal.accent).lineLimit(1)
                    Image(systemName: "chevron.down").font(.caption2).foregroundColor(pal.accent)
                }
            }
            Button { withAnimation(.easeInOut(duration: 0.2)) { compare = false } } label: {
                Image(systemName: "xmark").font(.caption2).foregroundColor(pal.inkSoft)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private var compareSelection: Binding<String> {
        Binding(
            get: { compareEdition?.id ?? "" },
            set: { compareEditionId = $0 }
        )
    }

    private func introBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { introExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text("Introduction")
                        .font(.caption).tracking(2).foregroundColor(pal.inkSoft)
                    Image(systemName: introExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2).foregroundColor(pal.inkSoft)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if introExpanded {
                ForEach(Array(text.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, para in
                    Text(para)
                        .font(.system(size: 16, design: .serif))
                        .italic()
                        .lineSpacing(5)
                        .foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Rectangle().fill(pal.rule).frame(height: 1).padding(.top, 6)
        }
        .padding(.bottom, 4)
    }

    private func sectionHeader(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.label.uppercased())
                .font(.caption).tracking(2).foregroundColor(pal.accent)
            if let title = section.title {
                Text(title).font(.system(.title3, design: .serif)).italic().foregroundColor(pal.ink)
            }
        }
        .padding(.top, 10)
    }

    // MARK: contents

    // Which section currently holds the dropped bookmark (if any).
    private var bookmarkSection: Section? {
        guard let bm = reading.bookmark(work.id) else { return nil }
        return currentEdition?.sections.first { bm == $0.id || bm.hasPrefix($0.id + ".") }
    }

    private var contentsSheet: some View {
        NavigationStack {
            List {
                if let bm = reading.bookmark(work.id) {
                    Button {
                        jumpToSegment(bm); showContents = false
                    } label: {
                        Label("Return to your bookmark", systemImage: "bookmark.fill")
                            .font(.subheadline.weight(.medium)).foregroundColor(pal.accent)
                    }
                    .listRowBackground(pal.rail)
                }
                ForEach(currentEdition?.sections ?? []) { section in
                    let isCurrent = section.id == currentSection?.id
                    let isBookmarked = section.id == bookmarkSection?.id
                    DisclosureGroup(isExpanded: expandedBinding(section.id)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(library.chapterOverview(workId: work.id, order: section.order)
                                 ?? "Overview coming soon.")
                                .font(.callout)
                                .foregroundColor(pal.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            Button { jumpTo(section) } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "book")
                                    Text("Read \(section.label)")
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(pal.accent))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    } label: {
                        HStack(spacing: 8) {
                            Text(section.label)
                                .font(.body.weight(isCurrent ? .semibold : .regular))
                                .foregroundColor(pal.ink)
                            if let title = section.title {
                                Text(title).font(.caption).foregroundColor(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if isBookmarked {
                                Image(systemName: "bookmark.fill").font(.caption2).foregroundColor(pal.gold)
                            }
                            if isCurrent {
                                Image(systemName: "book.fill").font(.caption2).foregroundColor(pal.accent)
                            }
                        }
                    }
                    .tint(pal.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(pal.paper)
            .navigationTitle("Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showContents = false }
                }
            }
        }
    }

    private func expandedBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { expandedBooks.contains(id) },
            set: { open in
                if open { expandedBooks.insert(id) } else { expandedBooks.remove(id) }
            }
        )
    }

    private func jumpTo(_ section: Section) {
        if let idx = currentEdition?.sections.firstIndex(where: { $0.id == section.id }) {
            currentBookIndex = idx
        }
        scrollTarget = section.id
        showContents = false
    }

    // MARK: actions

    private func switchEdition(to id: String) {
        guard id != currentEditionId else { return }
        currentEditionId = id
        dismissPopups()
    }

    private func showWord(_ word: String, at point: CGPoint) {
        selPopup = nil; selRange = nil; selSegmentId = nil; focusWord = nil
        wordPopup = WordPopup(term: word, def: dictionary.define(word) ?? passageGloss(word), point: point)
    }

    private func backgroundTap() {
        if wordPopup != nil || selPopup != nil || focusWord != nil { dismissPopups() }
    }

    private func dismissPopups() {
        wordPopup = nil
        selPopup = nil
        selRange = nil
        selSegmentId = nil
        focusWord = nil
    }

    @ViewBuilder
    private func selectionSaveCard(_ sp: SelPopup) -> some View {
        HStack(spacing: 10) {
            Button {
                saved.addHighlight(SavedHighlight(segmentId: sp.segmentId,
                                                  start: sp.range.lowerBound, end: sp.range.upperBound,
                                                  text: sp.text, workTitle: work.title, workId: work.id))
                selPopup = nil; selRange = nil; selSegmentId = nil
            } label: {
                Label("Highlight", systemImage: "highlighter").font(.caption.weight(.semibold))
                    .foregroundColor(pal.accent)
            }
            .buttonStyle(.plain)
            Divider().frame(height: 16)
            Button { dismissPopups() } label: {
                Image(systemName: "xmark").font(.caption2).foregroundColor(pal.inkSoft)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(Capsule().fill(pal.paper))
        .overlay(Capsule().stroke(pal.rule))
        .shadow(color: .black.opacity(0.20), radius: 10, y: 4)
    }

    // Place a popup near a tapped/selected point (in the reading area's coordinate
    // space), clamped to that area and lifted above the finger when there's room.
    private func popupPosition(_ p: CGPoint, in size: CGSize, card: CGSize) -> CGPoint {
        let m: CGFloat = 12
        let halfW = card.width / 2, halfH = card.height / 2
        let x = min(max(p.x, halfW + m), size.width - halfW - m)
        var y = p.y - halfH - 20
        if y < halfH + m { y = p.y + halfH + 28 }
        y = min(max(y, halfH + m), size.height - halfH - m)
        return CGPoint(x: x, y: y)
    }

    private func passageGloss(_ word: String) -> String? {
        guard let section = currentSection,
              let passage = library.passage(workId: work.id, sectionId: section.id) else { return nil }
        return passage.define?.first { WordDictionary.normalize($0.term) == word }?.gloss
    }
}
