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
    @State private var focusWord: String?
    @State private var selSegmentId: String?
    @State private var selRange: ClosedRange<Int>?
    @State private var selPopup: SelPopup?
    @State private var noteTarget: SavedHighlight?
    // Divergences (Lectio editions): where this rendering departs from older translations.
    @State private var divAnchors: [String: [Edition.Divergence]] = [:]     // segmentId -> markers
    @State private var divsBySection: [String: [Edition.Divergence]] = [:]  // sectionId -> rail list
    @State private var generalDivs: [Edition.Divergence] = []               // "throughout" notes
    @State private var divPopoverSegId: String?
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
            case .marks:    return "Margin"
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

    // The one selection card, anchored near the held word / end of the drag: a single
    // word shows its meaning with Highlight/Note/Explore; a span offers Highlight/Note.
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
                            // Compare splits the page; every other panel slides OVER the text
                            // instead — resizing the reading column re-lays-out every visible
                            // word, which is what made opening a panel feel slow.
                            HStack(alignment: .top, spacing: 0) {
                                readingColumn(ed)
                                if hSize == .regular, panel == .compare {
                                    Divider().overlay(pal.rule)
                                    sidePanel(.compare)
                                        .frame(width: min(480, max(320, geo.size.width * 0.42)))
                                        .background(pal.paper)
                                        .transition(.move(edge: .trailing))
                                }
                            }
                            .overlay(alignment: .trailing) {
                                if hSize == .regular, let p = panel, p != .compare {
                                    sidePanel(p)
                                        .frame(width: min(480, max(320, geo.size.width * 0.42)))
                                        .frame(maxHeight: .infinity)
                                        .background(p == .marks ? pal.rail : pal.paper)
                                        .overlay(alignment: .leading) { Divider().overlay(pal.rule) }
                                        .shadow(color: .black.opacity(0.15), radius: 16, x: -6, y: 0)
                                        .transition(.move(edge: .trailing))
                                }
                            }
                        } else {
                            Text("No edition available.").foregroundColor(pal.inkSoft)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        // Scrim that dismisses an open popup on a tap anywhere else.
                        if selPopup != nil {
                            Color.black.opacity(0.001)
                                .onTapGesture { dismissPopups() }
                        }
                        if let sp = selPopup {
                            selectionCard(sp)
                                .position(popupPosition(sp.point, in: rgeo.size,
                                                        card: CGSize(width: 300, height: sp.range.count == 1 ? 190 : 100)))
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
        // Write a note on a just-made highlight (the rail and Notes page have their own editors).
        .sheet(item: $noteTarget) { h in
            NoteEditorSheet(highlight: h, pal: pal, saved: saved)
                .presentationDetents([.medium])
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
            // Debug hook: LECTIO_DEBUG_SELECT=<word> selects the word's first occurrence
            // and shows the selection card (for screenshots).
            if let dbg = ProcessInfo.processInfo.environment["LECTIO_DEBUG_SELECT"], !dbg.isEmpty {
                let w = WordDictionary.normalize(dbg)
                outer: for sec in currentEdition?.sections ?? [] {
                    for seg in sec.segments {
                        let toks = WordFlowText.tokenize(seg.text)
                        if let i = toks.firstIndex(where: { WordDictionary.normalize($0) == w }) {
                            selSegmentId = seg.id
                            selRange = i...i
                            selPopup = SelPopup(segmentId: seg.id, range: i...i,
                                                text: toks[i], point: CGPoint(x: 300, y: 380))
                            scrollTarget = seg.id
                            break outer
                        }
                    }
                }
            }
            // Debug hook: LECTIO_DEBUG_CONTEXT shows the context rail (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONTEXT"] != nil {
                panel = .marks
            }
            // Debug hook: LECTIO_DEBUG_SEED_MARKS seeds a highlight with a note
            // (headless screenshots can't drag-select).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_SEED_MARKS"] != nil,
               let seg = currentEdition?.sections.first?.segments.first {
                let words = seg.text.split(separator: " ").map(String.init)
                let h = SavedHighlight(segmentId: seg.id, start: 0, end: max(0, min(9, words.count - 1)),
                                       text: words.prefix(10).joined(separator: " "),
                                       note: "This is the thread of the whole poem — watch how the anger cools into grief.",
                                       workTitle: work.title, workId: work.id)
                saved.addHighlight(h)
                // LECTIO_DEBUG_NOTE_EDITOR additionally opens the note editor on it.
                if ProcessInfo.processInfo.environment["LECTIO_DEBUG_NOTE_EDITOR"] != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        noteTarget = saved.highlight(id: h.id) ?? h
                    }
                }
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
        .task(id: currentEditionId) { rebuildDivergenceIndex() }
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

    // MARK: divergences — anchoring the "on the text" notes to the passages they belong to

    private static let quotedRe = try! NSRegularExpression(pattern: "[“\"]([^”\"]{2,80})[”\"]")

    // The quoted renderings inside a divergence's `lectio` field (e.g. “rage”,
    // “deadly Dream” / “baneful”) — the strings to look for in the text.
    private func lectioPhrases(_ d: Edition.Divergence) -> [String] {
        let ns = d.lectio as NSString
        let matches = Self.quotedRe.matches(in: d.lectio, range: NSRange(location: 0, length: ns.length))
        var phrases = matches.map { ns.substring(with: $0.range(at: 1)) }
        if phrases.isEmpty {
            let bare = d.lectio.trimmingCharacters(in: CharacterSet(charactersIn: " “”\"'.,"))
            if bare.count >= 3 { phrases = [bare] }
        }
        return phrases.sorted { $0.count > $1.count }
    }

    // The section order a locus names ("Book 4, line 2" → 4, "III.i" → 3, "Tablet IX" → 9).
    private func locusOrder(_ locus: String?) -> Int? {
        guard let locus else { return nil }
        var val = 0, found = false
        for ch in locus {
            if ch.isNumber, let d = ch.wholeNumberValue { val = val * 10 + d; found = true }
            else if found { break }
        }
        if found { return val }
        for token in locus.split(whereSeparator: { !$0.isLetter }) {
            if let v = romanValue(String(token)) { return v }
        }
        return nil
    }

    private func romanValue(_ s: String) -> Int? {
        let vals: [Character: Int] = ["I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000]
        guard !s.isEmpty, s.allSatisfy({ vals[$0] != nil }) else { return nil }
        var total = 0, prev = 0
        for ch in s.reversed() {
            let v = vals[ch]!
            total += v < prev ? -v : v
            prev = max(prev, v)
        }
        return total
    }

    // Build the divergence index for the open edition: each note anchors to the segment
    // holding its Lectio rendering (locus section first, then a whole-book search — loci
    // like the Comedy's "I.2" can't name the cantica); unanchorable notes fall back to
    // the locus section's rail list, or the general "throughout" list. Runs off-main —
    // the whole-book fallback scans every segment.
    private func rebuildDivergenceIndex() {
        guard let ed = currentEdition, let divs = ed.divergences, !divs.isEmpty else {
            divAnchors = [:]; divsBySection = [:]; generalDivs = []; return
        }
        let sections = ed.sections
        DispatchQueue.global(qos: .userInitiated).async {
            var anchors: [String: [Edition.Divergence]] = [:]
            var bySection: [String: [Edition.Divergence]] = [:]
            var general: [Edition.Divergence] = []

            func find(_ phrases: [String], in secs: [Section], minLen: Int) -> (String, String)? {
                for sec in secs {
                    for seg in sec.segments {
                        for p in phrases where p.count >= minLen {
                            if seg.text.range(of: p, options: [.caseInsensitive, .diacriticInsensitive]) != nil {
                                return (seg.id, sec.id)
                            }
                        }
                    }
                }
                return nil
            }

            for d in divs {
                let low = (d.locus ?? "").lowercased()
                if d.locus == nil || low.contains("throughout") || low.contains("title") {
                    general.append(d); continue
                }
                let phrases = lectioPhrases(d)
                let locusSection = locusOrder(d.locus).flatMap { o in sections.first { $0.order == o } }
                var hit: (String, String)? = nil
                if let sec = locusSection { hit = find(phrases, in: [sec], minLen: 3) }
                if hit == nil { hit = find(phrases, in: sections, minLen: 8) }
                if let (segId, secId) = hit {
                    anchors[segId, default: []].append(d)
                    bySection[secId, default: []].append(d)
                } else if let sec = locusSection {
                    bySection[sec.id, default: []].append(d)
                } else {
                    general.append(d)
                }
            }
            DispatchQueue.main.async {
                divAnchors = anchors
                divsBySection = bySection
                generalDivs = general
            }
        }
    }

    // The rail's "On the text" list for the section in view.
    private var railDivergences: [Edition.Divergence] {
        (currentSection.flatMap { divsBySection[$0.id] } ?? []) + generalDivs
    }

    // From the provenance sheet's divergence list straight to the passage: jump to the
    // anchored segment and open its marker popover; fall back to the locus section.
    private func showDivergenceInText(_ d: Edition.Divergence) {
        withAnimation(.easeInOut(duration: 0.2)) { panel = nil }
        if let segId = divAnchors.first(where: { $0.value.contains(d) })?.key {
            jumpToSegment(segId)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                divPopoverSegId = segId
            }
        } else if let order = locusOrder(d.locus),
                  let sec = currentEdition?.sections.first(where: { $0.order == order }) {
            jumpToSegment(sec.id)
        }
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
                                focusWord: focusWord,
                                savedWords: savedWordSet,
                                savedRanges: saved.ranges(forSegment: segment.id),
                                activeRange: selSegmentId == segment.id ? selRange : nil,
                                onSelectChange: { range in
                                    selPopup = nil
                                    selSegmentId = segment.id
                                    selRange = range
                                },
                                onSelectCommit: { range, text, point in
                                    selSegmentId = segment.id
                                    selRange = range
                                    selPopup = SelPopup(segmentId: segment.id, range: range,
                                                        text: text, point: point)
                                },
                                onTap: {
                                    if selPopup != nil || selRange != nil { dismissPopups() }
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
                            .overlay(alignment: .topTrailing) {
                                if let divs = divAnchors[segment.id] {
                                    divergenceMarker(segmentId: segment.id, divs: divs)
                                }
                            }
                            .onAppear {
                                topSegmentId = segment.id
                                // Track the book from segments too, not just headers — on a
                                // restore the section header sits just off-screen above the
                                // anchor, so headers alone leave the index stale.
                                if let idx = sectionIndex(containing: segment.id),
                                   idx != currentBookIndex {
                                    currentBookIndex = idx
                                }
                            }
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
                MarginRail(work: work, section: currentSection, divergences: railDivergences,
                           pal: pal, onJump: jumpToSegment, onWordJump: jumpToWord)
            case .info:
                if let ed = currentEdition {
                    ProvenanceSheet(edition: ed, workTitle: work.title, pal: pal,
                                    onShowInText: { showDivergenceInText($0) })
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
        if selPopup != nil || selRange != nil || focusWord != nil { dismissPopups() }
    }

    private func dismissPopups() {
        selPopup = nil
        selRange = nil
        selSegmentId = nil
        focusWord = nil
    }

    // Commit the current selection as a highlight and return it (existing one if the
    // same span was highlighted before).
    private func commitHighlight(_ sp: SelPopup) -> SavedHighlight {
        let h = SavedHighlight(segmentId: sp.segmentId,
                               start: sp.range.lowerBound, end: sp.range.upperBound,
                               text: sp.text, workTitle: work.title, workId: work.id)
        saved.addHighlight(h)
        selPopup = nil; selRange = nil; selSegmentId = nil
        return saved.highlight(id: h.id) ?? h
    }

    // The one selection card. A held word leads with its meaning (understanding by
    // default, Explore for the deep dive); any selection can become a highlight or a note.
    @ViewBuilder
    private func selectionCard(_ sp: SelPopup) -> some View {
        let term: String? = sp.range.count == 1 ? WordDictionary.normalize(sp.text) : nil
        VStack(alignment: .leading, spacing: 10) {
            if let term, !term.isEmpty {
                let r = resolveWord(term)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(term).font(.system(.title3, design: .serif)).foregroundColor(pal.accent)
                    if let kind = r.kind, !kind.isEmpty {
                        Text(kind.uppercased())
                            .font(.system(size: 9, weight: .semibold)).tracking(0.6)
                            .foregroundColor(pal.inkSoft)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().stroke(pal.rule))
                    }
                    Spacer(minLength: 0)
                    Button {
                        saved.toggle(SavedWord(term: term, definition: r.def ?? "",
                                               workTitle: work.title, workId: work.id))
                    } label: {
                        Image(systemName: saved.isSaved(term) ? "bookmark.fill" : "bookmark")
                            .font(.subheadline)
                            .foregroundColor(saved.isSaved(term) ? pal.gold : pal.inkSoft)
                    }
                    .buttonStyle(.plain)
                }
                if let def = r.def, !def.isEmpty {
                    Text(def)
                        .font(.system(.footnote, design: .serif)).foregroundColor(pal.ink)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(SystemDictionary.hasDefinition(term)
                         ? "Not in this book's glossary — Explore opens the dictionary."
                         : "Not in this book's glossary yet.")
                        .font(.caption).foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text(spanSnippet(sp.text))
                    .font(.system(.footnote, design: .serif)).italic()
                    .foregroundColor(pal.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                cardAction("Highlight", "highlighter") { _ = commitHighlight(sp) }
                cardAction("Note", "square.and.pencil") { noteTarget = commitHighlight(sp) }
                if let term, !term.isEmpty {
                    NavigationLink(value: WordStudy(term: term, workId: work.id)) {
                        cardActionLabel("Explore", "text.magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { dismissPopups() })
                }
                Spacer(minLength: 0)
                Button { dismissPopups() } label: {
                    Image(systemName: "xmark").font(.caption2).foregroundColor(pal.inkSoft)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: 12).fill(pal.paper))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.rule))
        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
    }

    private func cardAction(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { cardActionLabel(title, icon) }
            .buttonStyle(.plain)
    }

    private func cardActionLabel(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(title).font(.caption.weight(.semibold)).lineLimit(1)
        }
        .fixedSize()
        .foregroundColor(pal.accent)
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(Capsule().stroke(pal.rule))
    }

    private func spanSnippet(_ t: String) -> String {
        let clean = t.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count > 110 ? "“" + clean.prefix(110).trimmingCharacters(in: .whitespaces) + "…”"
                                 : "“" + clean + "”"
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

    // MARK: divergence marker + card

    // A quiet asterisk in the right margin where the Lectio rendering makes a real
    // choice; tap for the older renderings and the reasoning.
    private func divergenceMarker(segmentId: String, divs: [Edition.Divergence]) -> some View {
        Button { divPopoverSegId = segmentId } label: {
            Image(systemName: "asterisk")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(pal.accent.opacity(0.6))
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: 28, y: -2)
        .popover(isPresented: divPopoverBinding(segmentId), arrowEdge: .trailing) {
            divergenceCard(divs)
        }
    }

    private func divPopoverBinding(_ segmentId: String) -> Binding<Bool> {
        Binding(get: { divPopoverSegId == segmentId },
                set: { if !$0 { divPopoverSegId = nil } })
    }

    private func divergenceCard(_ divs: [Edition.Divergence]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("ON THE TEXT")
                    .font(.caption2.weight(.semibold)).tracking(2).foregroundColor(pal.accent)
                ForEach(Array(divs.enumerated()), id: \.offset) { _, d in
                    DivergenceEntry(d: d, pal: pal)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 400, maxHeight: 420)
        .presentationCompactAdaptation(.popover)
        .background(pal.paper)
    }
}

// One divergence, laid out as phrase → older/Lectio renderings → the reasoning.
// Shared by the reader's marker popover and the Margin rail's "On the text" list.
struct DivergenceEntry: View {
    let d: Edition.Divergence
    let pal: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let phrase = d.phrase, !phrase.isEmpty {
                    Text(phrase).font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundColor(pal.ink)
                }
                if let locus = d.locus, !locus.isEmpty {
                    Text(locus).font(.caption2).foregroundColor(pal.inkSoft)
                }
            }
            renderingRow("Older", d.older, color: pal.inkSoft)
            renderingRow("Lectio", d.lectio, color: pal.ink)
            Text(d.note)
                .font(.footnote).foregroundColor(pal.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
        }
    }

    private func renderingRow(_ label: String, _ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold)).tracking(0.8)
                .foregroundColor(pal.inkSoft.opacity(0.8))
                .frame(width: 44, alignment: .trailing)
                .padding(.top, 2)
            Text(text)
                .font(.system(.caption, design: .serif))
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
