import SwiftUI

// Where to land when a book is opened from Notes, word study or the overview.
enum ReaderTarget: Hashable {
    case segment(String)   // a saved highlight's segment
    case word(String)      // a saved word — jump to its first occurrence
    case edition(String)   // a chosen edition, at the reader's place in the book
    case passage(String)   // a line quoted in Explore (any edition's segment), shown in the default edition
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
    @State private var compareScrollTarget: String?
    @State private var syncCmpSegId: String?
    @State private var panel: SidePanel?
    @State private var currentBookIndex = 0
    @State private var currentEditionId: String?
    @State private var scrollTarget: String?
    @State private var introExpanded = true
    // Per-scroll bookkeeping lives OUTSIDE SwiftUI state on purpose: segments appear and
    // disappear on every scroll frame, and writing that into @State re-rendered the whole
    // reader (header, rows, panels) each tick — the main source of scroll stutter.
    // Everything here is read on demand (persist, bookmarks, panel seeding), never bound to UI.
    private final class ScrollScratch {
        var visible: Set<String> = []
        var top: String?
        var rowsEditionId: String?
        var rows: [Row] = []
        var order: [String: Int] = [:]   // segmentId -> global reading order
    }
    @State private var scratch = ScrollScratch()
    @State private var didRestore = false
    @State private var animateScroll = true
    @State private var focusWord: String?
    @State private var selSegmentId: String?
    @State private var selRange: ClosedRange<Int>?
    @State private var selPopup: SelPopup?
    @State private var noteTarget: SavedHighlight?
    @State private var pendingNote: SavedHighlight?
    // Opened from Explore in the default edition: don't overwrite the place (and edition)
    // the reader keeps for this book unless they choose an edition here themselves.
    @State private var holdRememberedEdition = false   // waits for the iPhone panel sheet to close
    @State private var cardSize = CGSize(width: 300, height: 120)   // the selection card, as measured
    // Reading text size: five steps, 19pt (index 2) by default.
    @AppStorage("reader.textSizeStep") private var textSizeStep = 2
    static let textSizes: [CGFloat] = [15, 17, 19, 22, 25]
    private var textSize: CGFloat { Self.textSizes[min(max(textSizeStep, 0), Self.textSizes.count - 1)] }
    @State private var isSelecting = false          // true only during a live hold-select
    // Divergences (Lectio editions): where this rendering departs from older translations.
    @State private var divAnchors: [String: [Edition.Divergence]] = [:]     // segmentId -> markers
    @State private var divsBySection: [String: [Edition.Divergence]] = [:]  // sectionId -> rail list
    @State private var generalDivs: [Edition.Divergence] = []               // "throughout" notes
    @State private var divPopoverSegId: String?
    @State private var compareEditionId: String?
    // Compare-sync: tap a passage in one column and its matching passage lights up (and
    // scrolls into view) in the other, via the alignment spine (ReaderView.counterpart).
    @State private var syncMainSegId: String?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize

    private var pal: Palette { Palette.forScheme(colorScheme) }

    // One right-side drawer, switchable between all the ways to interact with the book.
    enum SidePanel: String, CaseIterable, Identifiable {
        case compare, marks, ask, info
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .compare:  return "rectangle.split.2x1"
            case .marks:    return "lightbulb"
            case .ask:      return "questionmark.bubble"
            case .info:     return "info.circle"
            }
        }
        var title: String {
            switch self {
            case .compare:  return "Compare"
            case .marks:    return "Margin"
            case .ask:      return DocentFeature.name
            case .info:     return "About this edition"
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

    // The one selection card, anchored near the held word / end of the drag: a single
    // word shows its meaning with Highlight/Note/Explore; a span offers Highlight/Note.

    // The topmost on-screen passage — a far better "what I'm reading" anchor than
    // the last row the LazyVStack materialized (which can sit below the fold).
    // O(visible segments) via the order index, not a scan of the whole book.
    private var firstVisibleSegmentId: String? {
        if let ed = currentEdition, scratch.rowsEditionId != ed.id { _ = rows(ed) }
        let first = scratch.visible.min {
            (scratch.order[$0] ?? .max) < (scratch.order[$1] ?? .max)
        }
        return first ?? scratch.top
    }
    struct SelPopup { var segmentId: String; var range: ClosedRange<Int>; var text: String; var point: CGPoint }

    // The work's editions by name, in reading order (Lectio first, the original last) —
    // for the menus; labels don't need the texts decoded.
    private var editionInfos: [EditionInfo] { library.editionInfos(for: work) }

    // The full texts, same order — only for cross-edition lookups (marks, bookmarks).
    private var editions: [Edition] { editionInfos.compactMap { library.edition($0.id) } }

    private var currentEdition: Edition? {
        if let id = currentEditionId, let e = library.edition(id) { return e }
        return library.edition(work.defaultEditionId) ?? editionInfos.first.flatMap { library.edition($0.id) }
    }

    // The edition shown alongside in compare mode (any edition other than the one being read).
    private var compareEdition: Edition? {
        if let id = compareEditionId, let e = library.edition(id), id != currentEdition?.id { return e }
        return editionInfos.first { $0.id != currentEdition?.id }.flatMap { library.edition($0.id) }
    }

    private var currentSection: Section? {
        guard let ed = currentEdition, !ed.sections.isEmpty else { return nil }
        return ed.sections.indices.contains(currentBookIndex)
            ? ed.sections[currentBookIndex] : ed.sections.first
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
                                readingColumn(ed, height: rgeo.size.height)
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
                                .onGeometryChange(for: CGSize.self) { $0.size } action: { cardSize = $0 }
                                .position(popupPosition(sp.point, in: rgeo.size, card: cardSize))
                        }
                    }
                    .coordinateSpace(name: "reader")
                }
            }
            .background(pal.paper)
        }
        .toolbar(.hidden, for: .navigationBar)
        // On iPhone (compact) the same switchable panel comes up as a bottom sheet.
        .sheet(isPresented: compactPanelBinding, onDismiss: {
            if let h = pendingNote { pendingNote = nil; noteTarget = h }
        }) {
            if let p = panel {
                sidePanel(p)
                    .background(pal.paper)
                    // A half-height bottom panel first, so the text stays visible;
                    // pull up for the full sheet.
                    .presentationDetents([.medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
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
                reading.markOpened(work.id)
                let st = reading.state(work.id)
                if let eid = st?.editionId, library.edition(eid) != nil { currentEditionId = eid }
                introExpanded = !reading.introSeen(work.id)
                reading.markIntroSeen(work.id)
                switch initialTarget {
                case .segment(let sid):
                    restorePosition(anchor: sid)
                case .passage(let sid):
                    // From Explore: the default edition at the line's counterpart. The edition
                    // the reader keeps for this book is left as it was.
                    currentEditionId = work.defaultEditionId
                    holdRememberedEdition = st?.editionId != nil && st?.editionId != work.defaultEditionId
                    if sectionIndex(containing: sid) != nil { restorePosition(anchor: sid) }
                    else if let mapped = resolveAcrossEditions(sid) { restorePosition(anchor: mapped) }
                    else if let sec = matchingSection(of: sid) { restorePosition(anchor: sec.id) }
                case .edition(let eid):
                    if library.edition(eid) != nil { currentEditionId = eid }
                    // The saved place may be in another edition: carry it across via the spine.
                    if let anchor = st?.segmentId ?? st?.sectionId {
                        if sectionIndex(containing: anchor) != nil { restorePosition(anchor: anchor) }
                        else if let mapped = resolveAcrossEditions(anchor) { restorePosition(anchor: mapped) }
                    }
                case .word(let term):
                    focusWord = WordDictionary.normalize(term)
                    if let seg = firstSegment(containing: term) { restorePosition(anchor: seg) }
                case nil:
                    if let anchor = st?.segmentId ?? st?.sectionId { restorePosition(anchor: anchor) }
                }
            }
            #if DEBUG
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
            // Debug hook: LECTIO_DEBUG_CONTEXT opens the Docent panel, where the
            // marks now live (for screenshots).
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_CONTEXT"] != nil {
                panel = docent.isAvailable ? .ask : .marks
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
                        presentNote(saved.highlight(id: h.id) ?? h)
                    }
                }
            }
            // Debug hook: LECTIO_DEBUG_COMPARE turns on side-by-side compare (for screenshots).
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
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_DOCENT"] != nil, docent.isAvailable {
                panel = .ask
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    anchorDocent()
                    if let q = ProcessInfo.processInfo.environment["LECTIO_DEBUG_DOCENT_ASK"], !q.isEmpty {
                        docent.ask(q)
                    }
                }
            }
            #endif
        }
        .onDisappear { persist() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { persist() }
            // Apple Intelligence may have been switched on while the app was away.
            else { docent.refresh() }
        }
        .task(id: currentEditionId) { rebuildDivergenceIndex() }
    }

    private func persist() {
        guard didRestore, !holdRememberedEdition else { return }
        // Save the passage at the TOP of the screen — the last-materialized row
        // (scratch.top) can sit below the fold, which restored the reader further
        // along than they actually were.
        let segId = firstVisibleSegmentId ?? scratch.top
        let progress = segId.flatMap { id in
            scratch.order[id].map { Double($0 + 1) / Double(max(scratch.order.count, 1)) }
        }
        reading.savePosition(workId: work.id,
                             editionId: currentEditionId,
                             sectionId: currentSection?.id,
                             segmentId: segId,
                             place: currentEdition?.place(sectionId: currentSection?.id, progress: progress),
                             progress: progress)
    }

    private func sectionIndex(containing anchorId: String) -> Int? {
        currentEdition?.sections.firstIndex { sec in
            anchorId == sec.id || anchorId.hasPrefix(sec.id + ".")
        }
    }

    // The section of the open edition with the same slug as another edition's segment's.
    private func matchingSection(of segId: String) -> Section? {
        guard let cur = currentEdition,
              let src = editionInfos.first(where: { segId.hasPrefix($0.id + ".") }),
              let slug = segId.dropFirst(src.id.count + 1).split(separator: ".").first else { return nil }
        return cur.sections.first { $0.id == cur.id + "." + slug }
    }

    private func restorePosition(anchor raw: String) {
        _ = currentEdition   // decoded, so omitted segments are known
        let anchor = library.readableAnchor(raw)
        if let idx = sectionIndex(containing: anchor) { currentBookIndex = idx }
        animateScroll = false
        DispatchQueue.main.async { scrollTarget = anchor }
    }

    private func jumpToSegment(_ segmentId: String) {
        // A mark dropped in another edition resolves here through the spine, so
        // bookmarks and highlights survive switching translations.
        var target = library.readableAnchor(segmentId)
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

    // Concept-bearing terms in this work — they get the whisper of an underline.
    private var importantWordSet: Set<String> {
        library.conceptTerms(workId: work.id)
    }

    private func firstSegment(containing term: String) -> String? {
        for sec in currentEdition?.sections ?? [] {
            for seg in sec.segments where WordDictionary.containsWord(term, in: seg.text) {
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
        if let src = findSegment(segId, in: from), let range = src.spine,
           let match = spineMatch(range, sourceText: src.text, in: to) {
            return match
        }
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

    // iPad: back · "Title · Edition ⌄" · centered chapter · icons. iPhone: back ·
    // "Title ⌄" (the edition picker lives in that menu) · chapter · icons, all on one
    // line at 375pt.
    private var header: some View {
        HStack(spacing: hSize == .regular ? 14 : 12) {
            iconButton("chevron.left") { dismiss() }
            editionMenu
            Spacer(minLength: 0)
            if hSize != .regular { chapterMenu.fixedSize().layoutPriority(1) }
            bookmarkMenu
            // The one persistent control row: these switch (and light up) the side
            // panel; the panel itself carries only a title and a close button.
            if hSize == .regular, editionInfos.count > 1 { panelButton(.compare) }
            // The Docent hides entirely where it can't run; its panel's marks
            // stay reachable through the Margin panel instead.
            panelButton(docent.isAvailable ? .ask : .marks)
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
        return Menu {
            // Resolved when the menu opens, so "here" is wherever the reader is now
            // (scrolling no longer re-renders the header).
            let hereId = firstVisibleSegmentId
            let hereMarked = hereId.map { marks.contains($0) } ?? false
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
                ForEach(editionInfos) { Text($0.label).tag($0.id) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(work.title).font(.subheadline.weight(.semibold)).foregroundColor(pal.ink)
                    .lineLimit(1).truncationMode(.tail)
                if hSize == .regular {
                    Text("·").foregroundColor(pal.inkSoft)
                    Text(currentEdition?.label ?? work.author)
                        .font(.caption).foregroundColor(pal.accent).lineLimit(1)
                }
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

    // Memoized per edition: rebuilding thousands of rows on every render made each
    // state change (selection, panel, section crossing) pay for the whole book.
    private func rows(_ ed: Edition) -> [Row] {
        if scratch.rowsEditionId == ed.id { return scratch.rows }
        var result: [Row] = []
        var order: [String: Int] = [:]
        var n = 0
        for section in ed.sections {
            result.append(.header(section))
            for segment in section.segments {
                result.append(.segment(segment))
                order[segment.id] = n
                n += 1
            }
        }
        scratch.rowsEditionId = ed.id
        scratch.rows = result
        scratch.order = order
        return result
    }

    private func readingColumn(_ ed: Edition, height: CGFloat) -> some View {
        // Computed once per render, not once per visible paragraph.
        let savedWords = savedWordSet
        let importantWords = importantWordSet
        return ScrollViewReader { proxy in
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
                                text: segment.text, pal: pal, fontSize: textSize,
                                focusWord: focusWord,
                                savedWords: savedWords,
                                importantWords: importantWords,
                                savedRanges: saved.ranges(forSegment: segment.id),
                                activeRange: selSegmentId == segment.id ? selRange : nil,
                                onSelectChange: { range in
                                    selPopup = nil
                                    selSegmentId = segment.id
                                    selRange = range
                                },
                                onSelectDrag: { p in
                                    autoScrollDuringSelection(p, height: height,
                                                              proxy: proxy, segmentId: segment.id)
                                },
                                onSelectCommit: { range, text, point in
                                    selSegmentId = segment.id
                                    selRange = range
                                    selPopup = SelPopup(segmentId: segment.id, range: range,
                                                        text: text, point: point)
                                },
                                onSelectionActive: { active in isSelecting = active },
                                onSelectCancel: {
                                    if selSegmentId == segment.id { selRange = nil; selSegmentId = nil }
                                },
                                onTapHighlight: { tokenIndex in
                                    openNote(segmentId: segment.id, tokenIndex: tokenIndex)
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
                                if reading.isBookmarked(work.id, segmentId: segment.id) {
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
                            .onAppear { segmentAppeared(segment.id) }
                            .onDisappear { scratch.visible.remove(segment.id) }
                        }
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
            // Only frozen while a hold-select is live, so the drag extends the selection
            // instead of scrolling; normal one-finger scrolling works everywhere otherwise.
            .scrollDisabled(isSelecting)
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
                scratch.visible.removeAll()
                // Stay on the same book when the user switches translation — but not on
                // the initial nil -> default assignment, which would scroll past the intro.
                guard oldValue != nil,
                      let ed = currentEdition, ed.sections.indices.contains(currentBookIndex) else { return }
                let id = ed.sections[currentBookIndex].id
                DispatchQueue.main.async { proxy.scrollTo(id, anchor: .top) }
            }
        }
    }

    // Scroll bookkeeping for a segment reaching the screen — no @State writes on the
    // common path, so plain reading never re-renders the reader.
    private func segmentAppeared(_ id: String) {
        scratch.visible.insert(id)
        scratch.top = id
        // Track the book from segments too, not just headers — on a restore the section
        // header sits just off-screen above the anchor, so headers alone leave the index stale.
        if let idx = sectionIndex(containing: id), idx != currentBookIndex {
            currentBookIndex = idx
        }
        // Compare follows the reading scroll: as new passages reach the top of the
        // main column, the compare column tracks their counterpart via the spine —
        // one scroll moves the whole page.
        if compare, hSize == .regular,
           let match = counterpart(of: id, from: currentEdition, to: compareEdition) {
            compareScrollTarget = match
        }
    }

    // Keep the selection growing past the screen edge: while the finger holds near the
    // top or bottom of the reading area, nudge the held paragraph into view.
    @State private var lastAutoScroll = Date.distantPast
    private func autoScrollDuringSelection(_ p: CGPoint, height: CGFloat,
                                           proxy: ScrollViewProxy, segmentId: String) {
        let now = Date()
        guard now.timeIntervalSince(lastAutoScroll) > 0.6 else { return }
        if p.y > height - 110 {
            lastAutoScroll = now
            withAnimation(.easeInOut(duration: 0.35)) { proxy.scrollTo(segmentId, anchor: .top) }
        } else if p.y < 110 {
            lastAutoScroll = now
            withAnimation(.easeInOut(duration: 0.35)) { proxy.scrollTo(segmentId, anchor: .bottom) }
        }
    }

    // MARK: the one right-side drawer (switchable: Contents · Compare · Marks · About)

    @ViewBuilder
    private func sidePanel(_ p: SidePanel) -> some View {
        VStack(spacing: 0) {
            panelHeader(p)
            Divider().overlay(pal.rule)
            switch p {
            case .compare:
                if let cmp = compareEdition { compareColumn(cmp) }
                else { emptyPanelNote("No other edition to compare yet.") }
            case .marks:
                MarginRail(work: work, section: currentSection, divergences: railDivergences,
                           pal: pal, onJump: jumpToSegment, onWordJump: jumpToWord)
            case .ask:
                DocentPanel(work: work, pal: pal, docent: docent, thread: docent.thread,
                            onReanchor: { anchorDocent(to: firstVisibleSegmentId) },
                            onJump: jumpToSegment, onWordJump: jumpToWord)
            case .info:
                if let ed = currentEdition {
                    VStack(spacing: 0) {
                        textSizeBar
                        Divider().overlay(pal.rule)
                        ProvenanceSheet(edition: ed, workTitle: work.title, pal: pal,
                                        onShowInText: { showDivergenceInText($0) },
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

    // Reading text size, five steps (A− / A+), remembered across books.
    private var textSizeBar: some View {
        HStack(spacing: 10) {
            Text("Text size").font(.subheadline.weight(.medium)).foregroundColor(pal.ink)
            Spacer(minLength: 0)
            sizeButton("A−", size: 13, enabled: textSizeStep > 0) { textSizeStep -= 1 }
            HStack(spacing: 4) {
                ForEach(Self.textSizes.indices, id: \.self) { i in
                    Circle().fill(i == textSizeStep ? pal.accent : pal.rule).frame(width: 5, height: 5)
                }
            }
            sizeButton("A+", size: 17, enabled: textSizeStep < Self.textSizes.count - 1) { textSizeStep += 1 }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func sizeButton(_ title: String, size: CGFloat, enabled: Bool,
                            _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: size, weight: .medium, design: .serif))
                .foregroundColor(enabled ? pal.accent : pal.inkSoft.opacity(0.4))
                .frame(width: 44, height: 32)
                .background(Capsule().stroke(pal.rule))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title == "A+" ? "Larger text" : "Smaller text")
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
        // Reset first, so choosing the same chapter again still scrolls.
        scrollTarget = nil
        DispatchQueue.main.async { scrollTarget = section.id }
    }

    // The book's key players — people, gods, and peoples from the curated
    // glossary — surfaced in the About panel as a who's-who.
    private var castEntries: [Enrichment.GlossEntry] {
        (library.enrichment[work.id]?.glossary ?? [])
            .filter { ["person", "god", "people"].contains($0.kind ?? "") }
    }

    private func compareColumn(_ ed: Edition) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Showing").font(.caption2).foregroundColor(pal.inkSoft)
                Menu {
                    Picker("Compare with", selection: compareSelection) {
                        ForEach(editionInfos.filter { $0.id != currentEdition?.id }) { e in
                            Text(e.label).tag(e.id)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(ed.label).font(.caption.weight(.medium))
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
                        // Align to the TOP so the counterpart sits level with the passage
                        // at the top of the main column (not floating mid-column, and never
                        // scrolled off-screen).
                        withAnimation { proxy.scrollTo(t, anchor: .top) }
                    }
                }
                .id(sec.id)   // reset scroll to top when the synced book changes
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed").font(.title2).foregroundColor(pal.inkSoft.opacity(0.5))
                    Text("This book isn't in this edition yet.")
                        .font(.callout).foregroundColor(pal.inkSoft).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            }
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
    private func anchorDocent(to segmentId: String? = nil) {
        guard docent.isAvailable, let ed = currentEdition else { return }
        let anchor = segmentId ?? selSegmentId ?? firstVisibleSegmentId
        if let ctx = docentContext(ed, anchor: anchor) { docent.anchor(ctx) }
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
            editionLabel: ed.label,
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
    // "1.611" -> ("1", 611); "Inferno.5" -> ("Inferno", 5).
    private func parseRef(_ s: String) -> (String, Int)? {
        guard let dot = s.lastIndex(of: "."), let n = Int(s[s.index(after: dot)...]) else { return nil }
        return (String(s[..<dot]), n)
    }
    private var compareSelection: Binding<String> {
        Binding(
            get: { compareEdition?.id ?? "" },
            set: { compareEditionId = $0 }
        )
    }

    // MARK: actions

    private func switchEdition(to id: String) {
        guard id != currentEditionId else { return }
        currentEditionId = id
        holdRememberedEdition = false   // the reader chose this edition
        dismissPopups()
    }

    // Tapped inside an existing highlight → open its note (the highlight covering the
    // tapped word, or the tightest one if several overlap).
    private func openNote(segmentId: String, tokenIndex: Int) {
        let hits = saved.highlights(forWork: work.id)
            .filter { $0.segmentId == segmentId && $0.range.contains(tokenIndex) }
            .sorted { ($0.end - $0.start) < ($1.end - $1.start) }
        if let h = hits.first { presentNote(h) }
    }

    // One sheet at a time: on iPhone the panel is itself a sheet, so close it first and
    // present the note editor once it has gone (the panel sheet's onDismiss).
    private func presentNote(_ h: SavedHighlight) {
        if hSize == .compact, panel != nil {
            pendingNote = h
            panel = nil
        } else {
            noteTarget = h
        }
    }

    // Tap-to-define resolution chain (BIBLE §8): curated in-context glossary first,
    // then any passage-level note. A nil def means the word is outside the curated
    // corpus — the selection card points to Explore (Apple's dictionary) instead.
    // A curated entry may carry a conceptId linking to the shared cross-work Concept node.
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
                        let isSaved = saved.isSaved(term, workId: work.id)
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.subheadline)
                            .foregroundColor(isSaved ? pal.gold : pal.inkSoft)
                    }
                    .buttonStyle(.plain)
                    closeButton
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
                HStack(alignment: .top, spacing: 8) {
                    Text(spanSnippet(sp.text))
                        .font(.system(.footnote, design: .serif)).italic()
                        .foregroundColor(pal.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    closeButton
                }
            }

            // The action chips wrap — four of them are wider than the card, and a plain
            // HStack overflowed the card's edges on both sides.
            FlowLayout(spacing: 8) {
                cardAction("Highlight", "highlighter") { _ = commitHighlight(sp) }
                cardAction("Note", "square.and.pencil") { presentNote(commitHighlight(sp)) }
                if let term, !term.isEmpty {
                    NavigationLink(value: WordStudy(term: term, workId: work.id)) {
                        cardActionLabel("Explore", "text.magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        dismissPopups()
                        if hSize == .compact { panel = nil }
                    })
                }
                if docent.isAvailable {
                    Button {
                        let sid = sp.segmentId
                        dismissPopups()
                        withAnimation(.easeInOut(duration: 0.2)) { panel = .ask }
                        anchorDocent(to: sid)
                    } label: {
                        cardActionLabel("Ask", "questionmark.bubble")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: 12).fill(pal.paper))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.rule))
        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
    }

    private var closeButton: some View {
        Button { dismissPopups() } label: {
            Image(systemName: "xmark").font(.caption2).foregroundColor(pal.inkSoft)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
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
