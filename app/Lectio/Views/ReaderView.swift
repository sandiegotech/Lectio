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

    @StateObject private var docent = DocentService()
    @State private var panel: SidePanel?
    @State private var currentBookIndex = 0
    @State private var currentEditionId: String?
    @State private var scrollTarget: String?
    @State private var introExpanded = true
    @State private var topSegmentId: String?
    @State private var visibleSegIds: Set<String> = []
    @State private var didRestore = false
    @State private var animateScroll = true
    @State private var wordPopup: WordPopup?
    @State private var focusWord: String?
    @State private var selSegmentId: String?
    @State private var selRange: ClosedRange<Int>?
    @State private var selPopup: SelPopup?
    // Compare: the reference passage (tapped in the main column) shown across all
    // other editions. Best-effort positional matching until the alignment spine exists.
    @State private var syncMainSegId: String?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize

    private var pal: Palette { Palette.forScheme(colorScheme) }

    // One right-side drawer, switchable between all the ways to interact with the book.
    enum SidePanel: String, CaseIterable, Identifiable {
        case compare, ask, info
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .compare:  return "rectangle.split.2x1"
            case .ask:      return "questionmark.bubble"
            case .info:     return "info.circle"
            }
        }
        var title: String {
            switch self {
            case .compare:  return "Compare"
            case .ask:      return DocentFeature.name
            case .info:     return "About"
            }
        }
    }
    private var compare: Bool { panel == .compare }
    // Open the panel to a mode, or close it if that mode is already showing.
    // No animation: animating the panel means animating a full re-layout of the
    // token-flow reading column, which stutters on device.
    private func togglePanel(_ p: SidePanel) {
        if panel == p { panel = nil }
        else {
            panel = p
            // Seed the reference with the passage being read, so the panel is
            // never empty; tapping any passage in the text replaces it.
            if p == .compare, syncMainSegId == nil { syncMainSegId = firstVisibleSegmentId }
            if p != .compare { syncMainSegId = nil }
            if p == .ask { anchorDocent() }
        }
    }

    // The topmost on-screen passage — a far better "what I'm reading" anchor than
    // the last row the LazyVStack materialized (which can sit below the fold).
    private var firstVisibleSegmentId: String? {
        guard let ed = currentEdition else { return nil }
        for sec in ed.sections {
            if let seg = sec.segments.first(where: { visibleSegIds.contains($0.id) }) {
                return seg.id
            }
        }
        return topSegmentId
    }

    // A word lookup popup, anchored near the tapped word.
    struct WordPopup { var term: String; var def: String?; var kind: String?; var conceptId: String?; var segmentId: String?; var point: CGPoint }
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
                                        .background(pal.paper)
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
                                     workTitle: work.title, workId: work.id,
                                     defineStream: docent.isAvailable && (wp.def?.isEmpty ?? true)
                                         ? { wordDefineStream(wp) } : nil,
                                     onAsk: docent.isAvailable
                                         ? { askDocentAboutWord(wp.term, segmentId: wp.segmentId) } : nil,
                                     pal: pal, onClose: dismissPopups)
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
                    .background(pal.paper)
                    // A half-height bottom panel first, so the text stays visible;
                    // pull up for the full sheet.
                    .presentationDetents([.medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
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
                                      point: CGPoint(x: 240, y: 360))
            }
            // Debug hook: LECTIO_DEBUG_CONTEXT opens the Docent panel, where the
            // marks now live (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONTEXT"] != nil {
                panel = .ask
            }
            // Debug hook: LECTIO_DEBUG_COMPARE opens the compare panel (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_COMPARE"] != nil {
                panel = .compare
                // Debug: pre-select a reference passage (headless screenshots can't tap).
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
            // Debug hook: LECTIO_DEBUG_DOCENT opens the Docent panel. Pair with
            // LECTIO_DEBUG_DOCENT_MOCK (canned provider, works on any host) and
            // LECTIO_DEBUG_DOCENT_ASK=<question> to show an answer (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_DOCENT"] != nil {
                panel = .ask
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    anchorDocent()
                    if let q = ProcessInfo.processInfo.environment["LECTIO_DEBUG_DOCENT_ASK"], !q.isEmpty {
                        docent.ask(q)
                    }
                }
            }
        }
        .onDisappear { persist() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { persist() } }
    }

    private func persist() {
        guard didRestore else { return }
        // Save the passage at the TOP of the screen — the last-materialized row
        // (topSegmentId) can sit below the fold, which restored the reader further
        // along than they actually were.
        reading.savePosition(workId: work.id,
                             editionId: currentEditionId,
                             sectionId: currentSection?.id,
                             segmentId: firstVisibleSegmentId ?? topSegmentId)
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
        // A mark dropped in another edition resolves here through the spine, so
        // bookmarks and highlights survive switching translations.
        var target = segmentId
        if sectionIndex(containing: segmentId) == nil,
           let resolved = resolveAcrossEditions(segmentId) {
            target = resolved
        }
        if let idx = sectionIndex(containing: target) { currentBookIndex = idx }
        scrollTarget = target
    }

    // Map a segment id from any other edition onto the one being read: spine
    // overlap when aligned, positional estimate otherwise.
    private func resolveAcrossEditions(_ segId: String) -> String? {
        guard let cur = currentEdition else { return nil }
        for ed in editions where ed.id != cur.id && segId.hasPrefix(ed.id + ".") {
            guard let seg = findSegment(segId, in: ed) else { continue }
            if let sp = seg.spine, let match = spineMatch(sp, sourceText: seg.text, in: cur) { return match }
            return counterpart(of: segId, from: ed, to: cur)
        }
        return nil
    }

    // The segment for an id, whichever edition owns it (for cross-edition marks).
    private func findSegmentAnywhere(_ id: String) -> Segment? {
        for ed in editions {
            if let seg = findSegment(id, in: ed) { return seg }
        }
        return nil
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

    // MARK: compare-sync — proportional passage matching across editions

    // MARK: the alignment spine — shared coordinates across editions

    // "1.611" -> ("1", 611); "Inferno.5" -> ("Inferno", 5).
    private func parseRef(_ s: String) -> (String, Int)? {
        guard let dot = s.lastIndex(of: "."), let n = Int(s[s.index(after: dot)...]) else { return nil }
        return (String(s[..<dot]), n)
    }

    // The segment in `ed` whose spine range best covers `range`. Candidates come
    // from spine overlap (with a few lines of slack, since v1 allocation is
    // proportional); among them, shared proper nouns with the source text pick
    // the exact moment, then midpoint, then overlap size.
    private func spineMatch(_ range: SpineRange, sourceText: String? = nil, in ed: Edition) -> String? {
        guard let (major, lo0) = parseRef(range.from), let (_, hi0) = parseRef(range.to) else { return nil }
        let lo = min(lo0, hi0), hi = max(lo0, hi0)
        let mid = Double(lo + hi) / 2
        let names = sourceText.map(properNouns) ?? []
        var best: (id: String, score: Double)? = nil
        for sec in ed.sections {
            for seg in sec.segments {
                guard let sp = seg.spine,
                      let (m, l0) = parseRef(sp.from), m == major,
                      let (_, h0) = parseRef(sp.to) else { continue }
                let l = min(l0, h0), h = max(l0, h0)
                guard min(hi + 3, h) - max(lo - 3, l) >= 0 else { continue }   // slack window
                let overlap = Double(min(hi, h) - max(lo, l))
                let holdsMidpoint = Double(l) <= mid && mid <= Double(h)
                let nouns = names.isEmpty ? 0 : names.intersection(properNouns(seg.text)).count
                let score = Double(nouns) * 10_000 + (holdsMidpoint ? 1_000 : 0) + max(overlap, 0)
                if best == nil || score > best!.score { best = (seg.id, score) }
            }
        }
        return best?.id
    }

    // A human-readable citation for a spine range: "1.17–21", "Inferno.5".
    private func spineText(_ r: SpineRange?) -> String? {
        guard let r, let (major, lo) = parseRef(r.from), let (_, hi) = parseRef(r.to) else { return nil }
        return hi > lo ? "\(major).\(lo)–\(hi)" : "\(major).\(lo)"
    }

    // The passage in `to` that best lines up with `segId` in `from`. Spine
    // overlap when both editions are aligned (exact shared coordinates); else
    // the positional estimate refined by shared proper nouns.
    private func counterpart(of segId: String, from: Edition?, to: Edition?) -> String? {
        guard let from, let to else { return nil }
        if let src = findSegment(segId, in: from), let range = src.spine,
           let match = spineMatch(range, sourceText: src.text, in: to) {
            return match
        }
        guard let bi = from.sections.firstIndex(where: { segId == $0.id || segId.hasPrefix($0.id + ".") }),
              to.sections.indices.contains(bi) else { return nil }
        // Historical editions open each book with apparatus (Pope's "ARGUMENT.",
        // Butler's chapter summary) — drop it so positions map body-to-body.
        let src = Array(bodySegments(from.sections[bi].segments))
        let dst = Array(bodySegments(to.sections[bi].segments))
        guard !src.isEmpty, !dst.isEmpty else { return nil }
        let i = src.firstIndex { $0.id == segId } ?? 0

        let srcTotal = src.reduce(0) { $0 + $1.text.count }
        let srcMid = src[..<i].reduce(0) { $0 + $1.text.count } + src[i].text.count / 2
        let frac = srcTotal > 0 ? Double(srcMid) / Double(srcTotal) : 0
        let dstTotal = Double(dst.reduce(0) { $0 + $1.text.count })
        var j = dst.count - 1
        var acc = 0.0
        for (k, seg) in dst.enumerated() {
            acc += Double(seg.text.count)
            if acc >= frac * dstTotal { j = k; break }
        }

        let names = properNouns(src[i].text)
        if !names.isEmpty {
            let window = (max(0, j - 4)...min(dst.count - 1, j + 4))
                .sorted { abs($0 - j) < abs($1 - j) }   // nearest first, so ties stay close
            var bestScore = 0
            for k in window {
                let score = names.intersection(properNouns(dst[k].text)).count
                if score > bestScore { j = k; bestScore = score }
            }
        }
        return dst[j].id
    }

    // A book's segments minus any leading apparatus: all-caps headings ("ARGUMENT.",
    // "THE CONTENTION OF ACHILLES AND AGAMEMNON."), the prose block a heading
    // introduces, and Butler-style chapter summaries — which chain clauses with
    // unspaced em-dashes (word—word), something body text here never does.
    private func bodySegments(_ segs: [Segment]) -> ArraySlice<Segment> {
        var start = 0
        var afterHeading = false
        while start < min(6, segs.count) {
            let t = segs[start].text.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.count < 80 && t.uppercased() == t {
                afterHeading = true; start += 1; continue
            }
            if start == 0 && t.count < 600 && chainedDashCount(t) >= 1 {
                start += 1; continue
            }
            if afterHeading {   // the content block belonging to a skipped heading
                afterHeading = false; start += 1; continue
            }
            break
        }
        return segs[start...]
    }

    // Occurrences of an em-dash jammed between letters (word—word).
    private func chainedDashCount(_ t: String) -> Int {
        let chars = Array(t)
        var n = 0
        for i in chars.indices where chars[i] == "—" {
            if i > 0, i + 1 < chars.count, chars[i - 1].isLetter, chars[i + 1].isLetter { n += 1 }
        }
        return n
    }

    // Capitalized words minus common sentence-openers — a cheap proper-noun proxy
    // for lining up the same moment across translations.
    private static let nounStoplist: Set<String> = [
        "The", "And", "But", "For", "Nor", "Yet", "She", "His", "Her", "They",
        "Then", "There", "This", "That", "These", "Those", "When", "While",
        "What", "Which", "Who", "How", "Now", "Come", "From", "With", "Not",
        "You", "Your", "Their", "Them", "Him", "Have", "Had", "Was", "Were",
    ]
    private func properNouns(_ text: String) -> Set<String> {
        var out = Set<String>()
        for raw in text.split(whereSeparator: { $0 == " " || $0 == "\n" }) {
            let t = raw.trimmingCharacters(in: .punctuationCharacters)
            guard t.count >= 3, let first = t.first, first.isUppercase,
                  !Self.nounStoplist.contains(t) else { continue }
            out.insert(t)
        }
        return out
    }

    // Tapped a passage in the main column → make it the compare reference.
    private func syncFromMain(_ segId: String) {
        guard compare else { return }
        syncMainSegId = segId
    }

    // The segment with this id, wherever it lives in the edition.
    private func findSegment(_ id: String, in ed: Edition) -> Segment? {
        for sec in ed.sections {
            if let seg = sec.segments.first(where: { $0.id == id }) { return seg }
        }
        return nil
    }

    // MARK: header (small, always present)

    private var header: some View {
        HStack(spacing: 14) {
            iconButton("chevron.left") { dismiss() }
            editionMenu
            Spacer()
            if hSize != .regular { chapterMenu }
            bookmarkMenu
            // The one persistent control row: these switch (and light up) the side
            // panel; the panel itself carries only a title and a close button.
            if hSize == .regular, editions.count > 1 { panelButton(.compare) }
            panelButton(.ask)
            panelButton(.info)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(pal.paper)
        // The current chapter, centered, as the table of contents — a dropdown
        // instead of a panel.
        .overlay { if hSize == .regular { chapterMenu } }
    }

    // The table of contents as a centered dropdown: the chapter you're in, and a
    // tap to jump anywhere.
    private var chapterMenu: some View {
        Menu {
            Picker("Chapter", selection: chapterSelection) {
                ForEach(currentEdition?.sections ?? []) { sec in
                    Text(sec.title.map { "\(sec.label) — \($0)" } ?? sec.label).tag(sec.id)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(currentSection?.label ?? "Contents")
                    .font(.subheadline.weight(.medium)).foregroundColor(pal.ink)
                Image(systemName: "chevron.down").font(.caption2).foregroundColor(pal.inkSoft)
            }
        }
    }

    private var chapterSelection: Binding<String> {
        Binding(
            get: { currentSection?.id ?? "" },
            set: { id in
                if let sec = currentEdition?.sections.first(where: { $0.id == id }) { jumpTo(sec) }
            }
        )
    }

    // Bookmarks, plural: drop one wherever you are, and jump between them — for
    // reading in several places at once, or finding your way back.
    private var bookmarkMenu: some View {
        let marks = reading.bookmarks(work.id)
        let hereId = firstVisibleSegmentId
        let hereMarked = hereId.map { marks.contains($0) } ?? false
        return Menu {
            Button {
                if let id = hereId { reading.toggleBookmark(work.id, segmentId: id) }
            } label: {
                Label(hereMarked ? "Remove the bookmark here" : "Drop a bookmark here",
                      systemImage: hereMarked ? "bookmark.slash" : "bookmark")
            }
            .disabled(hereId == nil)
            if !marks.isEmpty {
                Divider()
                ForEach(marks, id: \.self) { id in
                    Button { jumpToSegment(id) } label: {
                        Text(bookmarkTitle(id))
                        if let snip = bookmarkSnippet(id) { Text(snip) }
                    }
                }
            }
        } label: {
            Image(systemName: marks.isEmpty ? "bookmark" : "bookmark.fill")
                .font(.body.weight(.medium))
                .foregroundColor(marks.isEmpty ? pal.inkSoft : pal.accent)
        }
    }

    private func bookmarkTitle(_ segId: String) -> String {
        for ed in editions {
            if let sec = ed.sections.first(where: { segId == $0.id || segId.hasPrefix($0.id + ".") }) {
                return sec.label
            }
        }
        return "Bookmark"
    }

    private func bookmarkSnippet(_ segId: String) -> String? {
        guard let seg = findSegmentAnywhere(segId) else { return nil }
        let clean = seg.text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "“" + String(clean.prefix(40)).trimmingCharacters(in: .whitespaces) + "…”"
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

    private var editionMenu: some View {
        Menu {
            Picker("Edition", selection: editionSelection) {
                ForEach(editions) { ed in
                    Text(editionLabel(ed)).tag(ed.id)
                }
            }
            Divider()
            // The book you're reading has no overview page in the way — so My
            // Collection is reachable right from the title.
            Button {
                saved.toggleCollection(SavedBook(title: work.title, author: work.author))
            } label: {
                Label(saved.isInCollection(work.title) ? "In your collection" : "Add to My Collection",
                      systemImage: saved.isInCollection(work.title) ? "checkmark" : "plus")
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
                                onWord: { word, point in showWord(word, in: segment.id, at: point); syncFromMain(segment.id) },
                                onSelectCommit: { range, text, point in
                                    selSegmentId = segment.id
                                    selRange = range
                                    selPopup = SelPopup(segmentId: segment.id, range: range,
                                                        text: text, point: point)
                                }
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(compare && syncMainSegId == segment.id ? pal.accent.opacity(0.13) : .clear)
                                    .padding(.horizontal, -6).padding(.vertical, -3)
                            )
                            .overlay(alignment: .topLeading) {
                                if reading.isBookmarked(work.id, segmentId: segment.id) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 15)).foregroundColor(pal.gold)
                                        .offset(x: -26, y: -2)
                                }
                            }
                            .onAppear { visibleSegIds.insert(segment.id); topSegmentId = segment.id }
                            .onDisappear { visibleSegIds.remove(segment.id) }
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
                visibleSegIds.removeAll()
                // Stay on the same book when the user switches translation — but not on
                // the initial nil -> default assignment, which would scroll past the intro.
                guard oldValue != nil,
                      let ed = currentEdition, ed.sections.indices.contains(currentBookIndex) else { return }
                let id = ed.sections[currentBookIndex].id
                DispatchQueue.main.async { proxy.scrollTo(id, anchor: .top) }
            }
        }
    }

    // MARK: compare panel — one passage, every other edition

    // Not a second full-text column: the passage the reader tapped (or is reading),
    // rendered side by side across all the other editions as reference cards.
    @ViewBuilder
    private var comparePanel: some View {
        if let src = currentEdition,
           let refId = syncMainSegId ?? firstVisibleSegmentId,
           let refSeg = findSegment(refId, in: src) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THIS PASSAGE\(spineText(refSeg.spine).map { " · \($0)" } ?? "") · \(editionLabel(src).uppercased())")
                            .font(.caption2).tracking(1).foregroundColor(pal.inkSoft)
                        // No added quote marks — passages often carry their own.
                        Text(compareSnippet(refSeg.text))
                            .font(.system(.footnote, design: .serif)).italic()
                            .foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        Rectangle().fill(pal.rule).frame(height: 1)
                    }
                    ForEach(editions.filter { $0.id != src.id }) { ed in
                        compareCard(ed, refId: refId, from: src)
                    }
                    Text(refSeg.spine != nil
                         ? "Tap any passage in the text to bring it here. Aligned on the work's \(work.referenceScheme) spine."
                         : "Tap any passage in the text to bring it here. Matched by position — approximate.")
                        .font(.caption2).foregroundColor(pal.inkSoft.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            emptyPanelNote("Tap a passage in the text to see it in every other edition.")
        }
    }

    @ViewBuilder
    private func compareCard(_ ed: Edition, refId: String, from src: Edition) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let match = counterpart(of: refId, from: src, to: ed),
               let seg = findSegment(match, in: ed) {
                HStack(spacing: 6) {
                    Text(editionLabel(ed)).font(.caption.weight(.semibold)).foregroundColor(pal.accent)
                    if let cite = spineText(seg.spine) {
                        Text(cite).font(.caption2).foregroundColor(pal.inkSoft)
                    }
                }
                Text(seg.text)
                    .font(.system(size: 16, design: .serif))
                    .lineSpacing(5)
                    .foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(editionLabel(ed)).font(.caption.weight(.semibold)).foregroundColor(pal.accent)
                Text("This book isn't in this edition yet.")
                    .font(.caption).foregroundColor(pal.inkSoft)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(pal.rail))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(pal.rule))
    }

    private func compareSnippet(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count > 220 ? String(clean.prefix(220)).trimmingCharacters(in: .whitespaces) + "…" : clean
    }

    // MARK: the one right-side drawer (switchable: Contents · Compare · Marks · About)

    @ViewBuilder
    private func sidePanel(_ p: SidePanel) -> some View {
        VStack(spacing: 0) {
            panelHeader(p)
            Divider().overlay(pal.rule)
            switch p {
            case .compare:
                comparePanel
            case .ask:
                DocentPanel(work: work, pal: pal, docent: docent, thread: docent.thread,
                            onReanchor: { anchorDocent(to: firstVisibleSegmentId) },
                            onJump: jumpToSegment, onWordJump: jumpToWord)
            case .info:
                if let ed = currentEdition {
                    VStack(spacing: 0) {
                        collectionBar
                        Divider().overlay(pal.rule)
                        ProvenanceSheet(edition: ed, workTitle: work.title, pal: pal,
                                        cast: castEntries,
                                        chapterNote: currentSection.flatMap {
                                            library.chapterOverview(workId: work.id, order: $0.order)
                                        })
                    }
                } else { emptyPanelNote("No edition available.") }
            }
        }
    }

    // Just a title and a close button — switching panels lives in the header row,
    // so the controls never appear twice.
    private func panelHeader(_ p: SidePanel) -> some View {
        HStack(spacing: 6) {
            Text(p.title).font(.subheadline.weight(.semibold)).foregroundColor(pal.ink)
            Spacer(minLength: 0)
            Button { panel = nil } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                    .foregroundColor(pal.inkSoft).frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    // Check the open book in or out of My Collection, right from the About panel.
    private var collectionBar: some View {
        Button {
            saved.toggleCollection(SavedBook(title: work.title, author: work.author))
        } label: {
            let inColl = saved.isInCollection(work.title)
            HStack(spacing: 7) {
                Image(systemName: inColl ? "checkmark" : "plus")
                Text(inColl ? "In your collection" : "Add to My Collection")
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 0)
            }
            .foregroundColor(pal.accent)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    // Jump to a chapter from the header dropdown (any open panel stays put).
    private func jumpTo(_ section: Section) {
        if let idx = currentEdition?.sections.firstIndex(where: { $0.id == section.id }) {
            currentBookIndex = idx
        }
        scrollTarget = section.id
    }

    // The book's key players — people, gods, and peoples from the curated
    // glossary — surfaced in the About panel as a who's-who.
    private var castEntries: [Enrichment.GlossEntry] {
        (library.enrichment[work.id]?.glossary ?? [])
            .filter { ["person", "god", "people"].contains($0.kind ?? "") }
    }

    // MARK: actions

    private func switchEdition(to id: String) {
        guard id != currentEditionId else { return }
        currentEditionId = id
        dismissPopups()
    }

    private func showWord(_ word: String, in segmentId: String? = nil, at point: CGPoint) {
        selPopup = nil; selRange = nil; selSegmentId = nil; focusWord = nil
        let r = resolveWord(word)
        wordPopup = WordPopup(term: word, def: r.def, kind: r.kind, conceptId: r.conceptId,
                              segmentId: segmentId, point: point)
    }

    // The word popup's quick definition: the model reads the tapped word's passage.
    private func wordDefineStream(_ wp: WordPopup) -> AsyncThrowingStream<String, Error>? {
        guard let ed = currentEdition,
              let ctx = docentContext(ed, anchor: wp.segmentId ?? firstVisibleSegmentId) else { return nil }
        return docent.define(wp.term, context: ctx)
    }

    // Explore: the bubble already defined the word — the panel goes deeper, with
    // the conversation anchored to the passage it was tapped in.
    private func askDocentAboutWord(_ term: String, segmentId: String?) {
        let sid = segmentId
        dismissPopups()
        panel = .ask
        anchorDocent(to: sid)
        docent.ask("Tell me more about “\(term)” — its meaning and importance in this passage.")
    }

    // Tap-to-define resolution chain (BIBLE §8): curated in-context glossary first,
    // then any passage-level note. A nil def means the word is outside the curated
    // corpus — the WordCard streams a quick in-context definition from the on-device
    // model (the Docent), falling back to Apple's dictionary when no model exists.
    // A curated entry may carry a conceptId linking to the shared cross-work Concept node.
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
            if docent.isAvailable {
                Divider().frame(height: 16)
                Button {
                    let sid = sp.segmentId
                    dismissPopups()
                    withAnimation(.easeInOut(duration: 0.2)) { panel = .ask }
                    anchorDocent(to: sid)
                } label: {
                    Label("Ask", systemImage: "questionmark.bubble").font(.caption.weight(.semibold))
                        .foregroundColor(pal.accent)
                }
                .buttonStyle(.plain)
            }
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

    // MARK: the Docent — anchor the companion to a passage

    private func anchorDocent(to segmentId: String? = nil) {
        guard docent.isAvailable, let ed = currentEdition else { return }
        let anchor = segmentId ?? selSegmentId ?? firstVisibleSegmentId
        if let ctx = docentContext(ed, anchor: anchor) { docent.anchor(ctx) }
    }

    // The grounding bundle for a passage: its text, a little of what surrounds it,
    // and the curated editorial layer for that spot (glossary hits, passage notes,
    // the chapter overview). Small by design — it must share the on-device model's
    // 4k-token window with the conversation itself.
    private func docentContext(_ ed: Edition, anchor: String?) -> DocentContext? {
        var section: Section? = currentSection
        var segment: Segment? = nil
        if let anchor,
           let sec = ed.sections.first(where: { anchor == $0.id || anchor.hasPrefix($0.id + ".") }) {
            section = sec
            segment = sec.segments.first { $0.id == anchor }
        }
        guard let sec = section, let seg = segment ?? sec.segments.first else { return nil }
        let idx = sec.segments.firstIndex { $0.id == seg.id } ?? 0

        func trimmed(_ s: String, to n: Int) -> String {
            s.count > n ? String(s.prefix(n)) + "…" : s
        }

        var notes: [String] = []
        let lowered = seg.text.lowercased()
        for entry in library.enrichment[work.id]?.glossary ?? [] {
            guard notes.count < 8 else { break }
            let names = [entry.term] + (entry.aliases ?? [])
            if names.contains(where: { lowered.contains($0.lowercased()) }) {
                notes.append("\(entry.term): \(entry.gloss)")
            }
        }
        if let p = library.passage(workId: work.id, sectionId: sec.id) {
            for d in p.define ?? [] where notes.count < 12 {
                notes.append("\(d.term): \(d.gloss)")
            }
            if let people = p.people, !people.isEmpty {
                notes.append("Named elsewhere in this section (not necessarily in this passage): "
                             + people.joined(separator: ", "))
            }
        }

        return DocentContext(
            segmentId: seg.id,
            workTitle: work.title,
            author: work.author,
            composed: work.composed,
            editionLabel: editionLabel(ed),
            sectionLabel: sec.label,
            sectionTitle: sec.title,
            chapterOverview: library.chapterOverview(workId: work.id, order: sec.order)
                .map { trimmed($0, to: 500) },
            passage: trimmed(seg.text, to: 1600),
            before: idx > 0 ? trimmed(sec.segments[idx - 1].text, to: 300) : nil,
            after: idx + 1 < sec.segments.count ? trimmed(sec.segments[idx + 1].text, to: 300) : nil,
            notes: notes
        )
    }
}
