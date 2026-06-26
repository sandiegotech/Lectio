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
    @EnvironmentObject var saved: SavedStore
    @EnvironmentObject var reading: ReadingState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var panel: SidePanel?
    @State private var expandedBooks: Set<String> = []
    @State private var currentBookIndex = 0
    @State private var currentEditionId: String?
    @State private var scrollTarget: String?
    @State private var introExpanded = true
    @State private var topSegmentId: String?
    @State private var didRestore = false
    @State private var animateScroll = true
    @State private var wordPopup: WordPopup?
    @State private var focusWord: String?
    @State private var selSegmentId: String?
    @State private var selRange: ClosedRange<Int>?
    @State private var selPopup: SelPopup?
    @State private var compareEditionId: String?
    // Compare-sync: tap a passage in one column and its matching passage lights up (and
    // scrolls into view) in the other, via the alignment spine (ReaderView.counterpart).
    @State private var syncMainSegId: String?
    @State private var syncCmpSegId: String?
    @State private var compareScrollTarget: String?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize

    private var pal: Palette { Palette.forScheme(colorScheme) }

    // One right-side drawer, switchable between all the ways to interact with the book.
    enum SidePanel: String, CaseIterable, Identifiable {
        case contents, compare, marks, info
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .contents: return "list.bullet"
            case .compare:  return "rectangle.split.2x1"
            case .marks:    return "lightbulb"
            case .info:     return "info.circle"
            }
        }
        var title: String {
            switch self {
            case .contents: return "Contents"
            case .compare:  return "Compare"
            case .marks:    return "Marks"
            case .info:     return "About"
            }
        }
    }
    private var compare: Bool { panel == .compare }
    // Open the panel to a mode, or close it if that mode is already showing.
    private func togglePanel(_ p: SidePanel) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if panel == p { panel = nil }
            else {
                panel = p
                if p == .compare, compareEditionId == nil || compareEditionId == currentEdition?.id {
                    compareEditionId = editions.first { $0.id != currentEdition?.id }?.id
                }
                if p != .compare { syncMainSegId = nil; syncCmpSegId = nil }
            }
        }
    }

    // A word lookup popup, anchored near the tapped word.
    struct WordPopup { var term: String; var def: String?; var kind: String?; var conceptId: String?; var context: String?; var point: CGPoint }
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
                                if hSize == .regular, let p = panel {
                                    Divider().overlay(pal.rule)
                                    sidePanel(p)
                                        .frame(width: min(480, max(320, geo.size.width * 0.42)))
                                        .background(p == .marks ? pal.rail : pal.paper)
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
                            WordCard(term: wp.term, definition: wp.def, kind: wp.kind, conceptId: wp.conceptId,
                                     context: wp.context, workTitle: work.title, workId: work.id, pal: pal, onClose: dismissPopups)
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
        // On iPhone (compact) the same switchable panel comes up as a bottom sheet.
        .sheet(isPresented: compactPanelBinding) {
            if let p = panel {
                sidePanel(p)
                    .background(p == .marks ? pal.rail : pal.paper)
                    .presentationDetents([.large])
            }
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
                let r = resolveWord(w)
                wordPopup = WordPopup(term: w, def: r.def, kind: r.kind, conceptId: r.conceptId,
                                      context: nil, point: CGPoint(x: 240, y: 360))
            }
            // Debug hook: LECTIO_DEBUG_CONTEXT shows the context rail (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONTEXT"] != nil {
                panel = .marks
            }
            // Debug hook: LECTIO_DEBUG_COMPARE turns on side-by-side compare (for screenshots).
            if let c = ProcessInfo.processInfo.environment["LECTIO_DEBUG_COMPARE"] {
                panel = .compare
                if !c.isEmpty { compareEditionId = c }
                else { compareEditionId = editions.first { $0.id != currentEdition?.id }?.id }
                // Debug: pre-trigger a compare-sync highlight (headless screenshots can't tap).
                if ProcessInfo.processInfo.environment["LECTIO_DEBUG_SYNC"] != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        if let segs = currentEdition?.sections.first?.segments, segs.count > 3 {
                            syncFromMain(segs[3].id)
                        }
                    }
                }
            }
            // Debug hook: LECTIO_DEBUG_PROVENANCE opens the provenance sheet (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_PROVENANCE"] != nil {
                panel = .info
            }
            // Debug hook: LECTIO_DEBUG_CONTENTS opens the contents with book 1 expanded.
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONTENTS"] != nil {
                panel = .contents
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

    // MARK: compare-sync — passage matching across editions via the alignment spine

    // The fractional-span center of a segment on the shared spine, if tagged.
    private func spineCenter(_ seg: Segment) -> Double? {
        guard let s = seg.spine, let a = Double(s.from), let b = Double(s.to) else { return nil }
        return (a + b) / 2
    }

    // The passage in `to` that lines up with `segId` in `from`, via the alignment spine
    // (each segment's content-aligned position on the shared axis): the counterpart is the
    // `to` segment whose spine position is nearest. Segments with no spine — an edition's
    // argument heading or trailing apparatus — are skipped so they can't be a target.
    // Falls back to positional only when the tapped segment itself has no spine.
    private func counterpart(of segId: String, from: Edition?, to: Edition?) -> String? {
        guard let from, let to else { return nil }
        guard let bi = from.sections.firstIndex(where: { segId == $0.id || segId.hasPrefix($0.id + ".") }),
              to.sections.indices.contains(bi) else { return nil }
        let src = from.sections[bi].segments
        let dst = to.sections[bi].segments
        guard let i = src.firstIndex(where: { $0.id == segId }), !dst.isEmpty else { return nil }
        if let center = spineCenter(src[i]) {
            let spined = dst.filter { spineCenter($0) != nil }
            if let near = spined.min(by: { abs(spineCenter($0)! - center) < abs(spineCenter($1)! - center) }) {
                return near.id
            }
        }
        let j = src.count <= 1 ? 0 : Int((Double(i) * Double(dst.count - 1) / Double(src.count - 1)).rounded())
        return dst[min(max(j, 0), dst.count - 1)].id
    }

    // Tapped a passage in the main column → light up its match in the compare column.
    private func syncFromMain(_ segId: String) {
        guard compare, hSize == .regular else { return }
        syncMainSegId = segId
        if let match = counterpart(of: segId, from: currentEdition, to: compareEdition) {
            syncCmpSegId = match
            compareScrollTarget = match
        }
    }

    // Tapped a passage in the compare column → light up its match in the main column.
    private func syncFromCompare(_ segId: String) {
        syncCmpSegId = segId
        if let match = counterpart(of: segId, from: compareEdition, to: currentEdition) {
            syncMainSegId = match
            scrollTarget = match
        }
    }

    // MARK: header (small, always present)

    private var header: some View {
        HStack(spacing: 14) {
            iconButton("chevron.left") { dismiss() }
            editionMenu
            Spacer()
            panelButton(.contents)
            bookmarkButton
            if hSize == .regular, editions.count > 1 { panelButton(.compare) }
            panelButton(.marks)
            panelButton(.info)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(pal.paper)
    }

    // A header toggle for one drawer mode; lit when that mode is open.
    private func panelButton(_ p: SidePanel) -> some View {
        Button { togglePanel(p) } label: {
            Image(systemName: p.icon)
                .font(.body.weight(.medium))
                .foregroundColor(panel == p ? pal.accent : pal.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private var compactPanelBinding: Binding<Bool> {
        Binding(get: { hSize == .compact && panel != nil },
                set: { if !$0 { panel = nil } })
    }

    // Side-by-side translation compare (iPad). Reads the same book in two editions at once,
    // following you book-to-book as you scroll the main column.
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
                                onWord: { word, point in showWord(word, at: point, context: segment.text); syncFromMain(segment.id) },
                                onSelectCommit: { range, text, point in
                                    selSegmentId = segment.id
                                    selRange = range
                                    selPopup = SelPopup(segmentId: segment.id, range: range,
                                                        text: text, point: point)
                                },
                                onTap: {
                                    if wordPopup != nil || selPopup != nil { dismissPopups() }
                                    else { syncFromMain(segment.id) }
                                }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(compare && syncMainSegId == segment.id ? pal.accent.opacity(0.13) : .clear)
                                    .padding(.horizontal, -6).padding(.vertical, -3)
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
            HStack(spacing: 6) {
                Text("Showing").font(.caption2).foregroundColor(pal.inkSoft)
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
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            Divider().overlay(pal.rule)
            if ed.sections.indices.contains(currentBookIndex) {
                let sec = ed.sections[currentBookIndex]
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader(sec)
                            ForEach(sec.segments) { seg in
                                Text(seg.text)
                                    .font(.system(size: 17, design: .serif))
                                    .lineSpacing(6)
                                    .foregroundColor(pal.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(syncCmpSegId == seg.id ? pal.accent.opacity(0.13) : .clear)
                                            .padding(.horizontal, -6).padding(.vertical, -3)
                                    )
                                    .id(seg.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture { syncFromCompare(seg.id) }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24).padding(.vertical, 20)
                    }
                    .onChange(of: compareScrollTarget) { _, t in
                        guard let t else { return }
                        withAnimation { proxy.scrollTo(t, anchor: .center) }
                    }
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

    private var compareSelection: Binding<String> {
        Binding(
            get: { compareEdition?.id ?? "" },
            set: { compareEditionId = $0 }
        )
    }

    // MARK: the one right-side drawer (switchable: Contents · Compare · Marks · About)

    @ViewBuilder
    private func sidePanel(_ p: SidePanel) -> some View {
        VStack(spacing: 0) {
            panelTabBar(p)
            Divider().overlay(pal.rule)
            switch p {
            case .contents:
                contentsPanel
            case .compare:
                if let cmp = compareEdition { compareColumn(cmp) }
                else { emptyPanelNote("No other edition to compare yet.") }
            case .marks:
                MarginRail(work: work, pal: pal, onJump: jumpToSegment, onWordJump: jumpToWord)
            case .info:
                if let ed = currentEdition {
                    ProvenanceSheet(edition: ed, workTitle: work.title, pal: pal)
                } else { emptyPanelNote("No edition available.") }
            }
        }
    }

    private func panelTabBar(_ p: SidePanel) -> some View {
        // On iPad the top header already switches panels, so the drawer just needs a
        // title + close (one nav bar). On iPhone the header is hidden behind the bottom
        // sheet, so we keep the switcher tabs here.
        let tabs = SidePanel.allCases.filter { $0 != .compare || (hSize == .regular && editions.count > 1) }
        return HStack(spacing: 6) {
            Text(p.title).font(.subheadline.weight(.semibold)).foregroundColor(pal.ink)
            Spacer(minLength: 0)
            if hSize == .compact {
                ForEach(tabs) { tab in
                    Button { withAnimation(.easeInOut(duration: 0.15)) { panel = tab } } label: {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(p == tab ? pal.paper : pal.inkSoft)
                            .frame(width: 32, height: 28)
                            .background(RoundedRectangle(cornerRadius: 7)
                                .fill(p == tab ? pal.accent : pal.rule.opacity(0.35)))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button { withAnimation(.easeInOut(duration: 0.2)) { panel = nil } } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                    .foregroundColor(pal.inkSoft).frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private func emptyPanelNote(_ s: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed").font(.title2).foregroundColor(pal.inkSoft.opacity(0.5))
            Text(s).font(.callout).foregroundColor(pal.inkSoft).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(28)
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

    private var contentsPanel: some View {
            List {
                if let bm = reading.bookmark(work.id) {
                    Button {
                        jumpToSegment(bm); panel = nil
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
                            if let ov = library.chapterOverview(workId: work.id, order: section.order),
                               !ov.isEmpty {
                                Text(ov)
                                    .font(.callout)
                                    .foregroundColor(pal.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
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
        panel = nil
    }

    // MARK: actions

    private func switchEdition(to id: String) {
        guard id != currentEditionId else { return }
        currentEditionId = id
        dismissPopups()
    }

    private func showWord(_ word: String, at point: CGPoint, context: String? = nil) {
        selPopup = nil; selRange = nil; selSegmentId = nil; focusWord = nil
        let r = resolveWord(word)
        wordPopup = WordPopup(term: word, def: r.def, kind: r.kind, conceptId: r.conceptId, context: context, point: point)
    }

    // Tap-to-define resolution chain (BIBLE §8): curated in-context glossary first,
    // then any passage-level note. A nil def means the word is outside the curated
    // corpus — the WordCard offers Apple's on-device dictionary, then Gloss. A curated
    // entry may carry a conceptId linking to the shared cross-work Concept node.
    private func resolveWord(_ word: String) -> (def: String?, kind: String?, conceptId: String?) {
        if let entry = library.glossEntry(workId: work.id, term: word) {
            return (entry.gloss, entry.kind, entry.conceptId)
        }
        return (passageGloss(word), nil, nil)
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
