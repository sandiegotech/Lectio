import SwiftUI
import UIKit

// The paragraph's own origin in the reader coordinate space — combined with the
// layout-local token frames FlowLayout reports, this maps touches to words with a
// single GeometryReader instead of one per token.
struct FlowOriginKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { value = nextValue() }
}

// Renders a paragraph as individually laid-out words so the reader can:
//   • press & hold a word        → it becomes the selection (and its meaning pops up on release)
//   • keep holding and drag      → extend the selection across a phrase or sentence
//   • release                    → one compact card: the meaning + Highlight / Note / Explore
//   • tap                        → dismiss an open popup (or sync the compare column)
// The drag is gated behind the long-press (a sequenced gesture), so a quick swipe still
// scrolls — only a deliberate hold claims the touch for selection.
struct WordFlowText: View {
    // Holds token frames without triggering a re-render (used to anchor popups & map drags).
    // `local` frames come straight from FlowLayout; `origin` lifts them into reader space.
    final class FrameBox {
        var local: [Int: CGRect] = [:]
        var origin: CGPoint = .zero
        func frame(_ i: Int) -> CGRect? {
            local[i].map { $0.offsetBy(dx: origin.x, dy: origin.y) }
        }
    }

    let text: String
    let pal: Palette
    var space: String = "reader"
    var focusWord: String? = nil          // a saved word jumped-to from the panel: lightly highlighted
    var savedWords: Set<String> = []      // saved words: a light gold underline wherever they appear
    var importantWords: Set<String> = []  // concept-bearing terms: a whisper of an accent underline
    var savedRanges: [ClosedRange<Int>] = []
    var activeRange: ClosedRange<Int>? = nil
    var onSelectChange: (ClosedRange<Int>) -> Void = { _ in }
    var onSelectDrag: (CGPoint) -> Void = { _ in }   // live drag location (drives edge auto-scroll)
    var onSelectCommit: (ClosedRange<Int>, String, CGPoint) -> Void = { _, _, _ in }
    var onTap: () -> Void = {}

    // Tokenized once at creation — body indexes these hundreds of times per layout pass,
    // and recomputing the split on every access made each render O(n²).
    private let tokens: [String]
    private let normTokens: [String]

    @State private var box = FrameBox()
    @State private var pressAnchor: Int? = nil    // token under the finger when the hold began
    @State private var dragAnchor: Int? = nil     // selection start once the drag is live
    @Environment(\.colorScheme) private var scheme

    init(text: String, pal: Palette, space: String = "reader",
         focusWord: String? = nil, savedWords: Set<String> = [],
         importantWords: Set<String> = [],
         savedRanges: [ClosedRange<Int>] = [], activeRange: ClosedRange<Int>? = nil,
         onSelectChange: @escaping (ClosedRange<Int>) -> Void = { _ in },
         onSelectDrag: @escaping (CGPoint) -> Void = { _ in },
         onSelectCommit: @escaping (ClosedRange<Int>, String, CGPoint) -> Void = { _, _, _ in },
         onTap: @escaping () -> Void = {}) {
        self.text = text
        self.pal = pal
        self.space = space
        self.focusWord = focusWord
        self.savedWords = savedWords
        self.importantWords = importantWords
        self.savedRanges = savedRanges
        self.activeRange = activeRange
        self.onSelectChange = onSelectChange
        self.onSelectDrag = onSelectDrag
        self.onSelectCommit = onSelectCommit
        self.onTap = onTap
        self.tokens = Self.tokenize(text)
        self.normTokens = self.tokens.map { WordDictionary.normalize($0) }
    }

    private var flow: FlowLayout {
        FlowLayout(spacing: 0, lineSpacing: 7).reporting { [box] i, f in box.local[i] = f }
    }

    var body: some View {
        flow {
            ForEach(tokens.indices, id: \.self) { i in
                if tokens[i] == "\n" {
                    // A hard line break (verse): zero-size marker the layout breaks on.
                    Color.clear.frame(width: 0, height: 0)
                        .layoutValue(key: LineBreakKey.self, value: true)
                } else {
                    Text(tokens[i])
                        .font(.system(size: 19, design: .serif))
                        .foregroundColor(pal.ink)
                        .underline(underlineColor(i) != nil, color: underlineColor(i) ?? .clear)
                        .background(tokenHighlight(i))
                        .layoutValue(key: TokenIndexKey.self, value: i)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap() }
                        // Records which word the hold began on (the sequenced gesture below
                        // has no location of its own until the finger moves).
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.26)
                                .onEnded { _ in pressAnchor = i }
                        )
                }
            }
        }
        .background(GeometryReader { g in
            Color.clear.preference(key: FlowOriginKey.self,
                                   value: g.frame(in: .named(space)).origin)
        })
        .onPreferenceChange(FlowOriginKey.self) { [box] in box.origin = $0 }
        // Hold to select, keep holding to extend. Sequencing the drag behind the long
        // press means a plain swipe never loses the scroll — only a completed hold
        // claims the touch for selection.
        .gesture(
            LongPressGesture(minimumDuration: 0.28)
                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(space)))
                .onChanged { value in
                    guard case .second(true, let drag) = value else { return }
                    if let loc = drag?.location, let i = tokenIndex(at: loc) {
                        if dragAnchor == nil {
                            dragAnchor = pressAnchor ?? i
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        let a = dragAnchor ?? i
                        onSelectChange(min(a, i)...max(a, i))
                        onSelectDrag(loc)
                    } else if dragAnchor == nil, let a = pressAnchor {
                        dragAnchor = a
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelectChange(a...a)
                    }
                }
                .onEnded { value in
                    defer { pressAnchor = nil; dragAnchor = nil }
                    guard case .second(true, let drag) = value else { return }
                    let endIdx = drag.flatMap { tokenIndex(at: $0.location) }
                    guard let a = dragAnchor ?? pressAnchor ?? endIdx else { return }
                    let b = endIdx ?? a
                    let r = min(a, b)...max(a, b)
                    let point = drag?.location ?? center(b)
                    onSelectCommit(r, selectedText(r), point)
                }
        )
    }

    // Word tokens (each keeps its trailing space), with a "\n" marker wherever the
    // source text breaks a line — so verse keeps its lines while prose flows normally.
    static func tokenize(_ text: String) -> [String] {
        var out: [String] = []
        for (li, line) in text.components(separatedBy: "\n").enumerated() {
            if li > 0 { out.append("\n") }
            for w in line.split(separator: " ", omittingEmptySubsequences: true) {
                out.append(String(w) + " ")
            }
        }
        return out
    }

    private func norm(_ i: Int) -> String { normTokens[i] }

    private func center(_ i: Int) -> CGPoint {
        let f = box.frame(i) ?? .zero
        return CGPoint(x: f.midX, y: f.midY)
    }

    // The token nearest a touch point — exact hit first, then closest by line (vertical
    // distance weighted heavily so a drag past the margin stays on its own line).
    // Compares in layout-local space (one subtraction) rather than lifting every frame.
    private func tokenIndex(at p: CGPoint) -> Int? {
        let lp = CGPoint(x: p.x - box.origin.x, y: p.y - box.origin.y)
        var best: Int? = nil
        var bestDist = CGFloat.greatestFiniteMagnitude
        for (i, f) in box.local {
            if f.contains(lp) { return i }
            let dy = max(0, max(f.minY - lp.y, lp.y - f.maxY))
            let dx = max(0, max(f.minX - lp.x, lp.x - f.maxX))
            let d = dy * 8 + dx
            if d < bestDist { bestDist = d; best = i }
        }
        return best
    }

    // Dark mode washes the reading text out under a solid tint — keep highlights lighter at night.
    private func op(_ light: Double, _ dark: Double) -> Double { scheme == .dark ? dark : light }

    // The quiet layer: saved words carry a light gold underline; concept-bearing terms a
    // whisper of the accent — enough to invite a hold, never enough to interrupt reading.
    private func underlineColor(_ i: Int) -> Color? {
        let w = normTokens[i]
        guard !w.isEmpty else { return nil }
        if savedWords.contains(w) { return pal.gold.opacity(op(0.6, 0.45)) }
        if importantWords.contains(w) { return pal.accent.opacity(op(0.32, 0.26)) }
        return nil
    }

    // Saved words no longer tint the page — they carry the light underline instead;
    // backgrounds are reserved for real highlights, the live selection, and jump focus.
    @ViewBuilder
    private func tokenHighlight(_ i: Int) -> some View {
        let inActive = activeRange?.contains(i) ?? false
        let inSaved = savedRanges.contains { $0.contains(i) }
        let isFocus = (focusWord != nil) && norm(i) == focusWord
        if inActive {
            Rectangle().fill(pal.accent.opacity(op(0.22, 0.16)))
        } else if inSaved {
            Rectangle().fill(pal.gold.opacity(op(0.30, 0.18)))
        } else if isFocus {
            Rectangle().fill(pal.gold.opacity(op(0.22, 0.14)))
        } else {
            Color.clear
        }
    }

    private func selectedText(_ r: ClosedRange<Int>) -> String {
        r.compactMap { tokens.indices.contains($0) ? tokens[$0] : nil }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Compact lookup card shown in the popup overlay when a word is tapped.
struct WordCard: View {
    let term: String
    let definition: String?
    var kind: String? = nil           // set when the entry came from the curated glossary
    var conceptId: String? = nil      // links to a shared Concept node, if any
    var context: String? = nil        // the passage the word sits in, sent on to Gloss
    let workTitle: String?
    let workId: String?
    let pal: Palette
    let onClose: () -> Void
    @EnvironmentObject var saved: SavedStore
    @EnvironmentObject var library: Library

    private var concept: Concept? { conceptId.flatMap { library.concept(id: $0) } }
    private var hasDefinition: Bool { (definition?.isEmpty == false) }
    // Tier 2: offer Apple's on-device dictionary only when the word isn't curated
    // and the OS actually has an entry for it.
    private var systemHasDefinition: Bool {
        !hasDefinition && SystemDictionary.hasDefinition(term)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(term).font(.system(.title3, design: .serif)).foregroundColor(pal.accent)
                if let kind, !kind.isEmpty { kindChip(kind) }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.caption2)
                }
                .buttonStyle(.plain).foregroundColor(pal.inkSoft)
            }
            if let def = definition, !def.isEmpty {
                Text(def).font(.system(.footnote, design: .serif)).foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(systemHasDefinition
                     ? "Not in this book's glossary — look it up in the dictionary, or go deeper in Gloss."
                     : "Not in this book's glossary. Save it for study, or look it up in Gloss.")
                    .font(.caption).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let concept { conceptBlock(concept) }
            HStack(spacing: 8) {
                Button {
                    saved.toggle(SavedWord(term: term, definition: definition ?? "",
                                           workTitle: workTitle, workId: workId))
                } label: {
                    Label(saved.isSaved(term) ? "Saved" : "Save word",
                          systemImage: saved.isSaved(term) ? "bookmark.fill" : "bookmark")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(saved.isSaved(term) ? pal.accent : pal.paper)
                        .foregroundColor(saved.isSaved(term) ? .white : pal.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(pal.rule))
                }
                .buttonStyle(.plain)
                if systemHasDefinition {
                    Button {
                        SystemDictionary.lookUp(term)
                    } label: {
                        Label("Dictionary", systemImage: "character.book.closed")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .foregroundColor(pal.accent)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(pal.rule))
                    }
                    .buttonStyle(.plain)
                }
            }
            // The in-app deep dive — the Gloss experience without leaving the book.
            if let workId {
                NavigationLink(value: WordStudy(term: term, workId: workId)) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.magnifyingglass").font(.caption2)
                        Text("Study this word").font(.caption.weight(.semibold))
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(pal.accent))
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { onClose() })
            }
            glossLink
        }
        .padding(14)
        .frame(width: 260)
        .background(RoundedRectangle(cornerRadius: 12).fill(pal.paper))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.rule))
        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
    }

    // The shared-concept payoff: the original-language word, how it traveled into
    // English, and the other works where the same idea recurs (the cross-work web).
    @ViewBuilder
    private func conceptBlock(_ c: Concept) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let o = c.original {
                HStack(spacing: 6) {
                    Text(o.lemma).font(.system(.footnote, design: .serif)).foregroundColor(pal.ink)
                    if let t = o.translit { Text(t).font(.caption.italic()).foregroundColor(pal.inkSoft) }
                    if let lit = o.literal {
                        Text("“\(lit)”").font(.caption).foregroundColor(pal.inkSoft)
                    }
                }
            }
            if let sense = c.senseHistory {
                Text(sense).font(.caption).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !otherWorks(c).isEmpty {
                (Text("Also in ").foregroundColor(pal.inkSoft)
                 + Text(otherWorks(c).joined(separator: ", ")).foregroundColor(pal.accent))
                    .font(.system(size: 11, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)
            }
            // Into the idea's own page — the cross-work thread, browsable.
            NavigationLink(value: c) {
                HStack(spacing: 4) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 9))
                    Text("Trace this idea").font(.caption.weight(.semibold))
                    Image(systemName: "chevron.right").font(.system(size: 8, weight: .semibold))
                }
                .foregroundColor(pal.accent)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { onClose() })
        }
        .padding(.top, 2)
    }

    // Titles of the other works this concept appears in (excluding the one being read).
    private func otherWorks(_ c: Concept) -> [String] {
        (c.appearsIn ?? [])
            .filter { $0 != workId }
            .compactMap { library.workTitle(id: $0) }
    }

    private func kindChip(_ kind: String) -> some View {
        Text(kind.uppercased())
            .font(.system(size: 9, weight: .semibold)).tracking(0.6)
            .foregroundColor(pal.inkSoft)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().stroke(pal.rule))
    }

    // Is the sibling app installed? (Requires `gloss` in LSApplicationQueriesSchemes.)
    private var glossInstalled: Bool {
        guard let u = URL(string: "gloss://define") else { return false }
        return UIApplication.shared.canOpenURL(u)
    }

    // Bridge to the sibling app. If Gloss is installed it's a clear call-to-action, set
    // apart from the definition text; if not, a quiet link to discover it. Either way the
    // word and the passage it sits in travel along.
    private var glossLink: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(pal.rule)
            if glossInstalled {
                // Quiet row — the in-app Study capsule above is the primary deep dive now.
                Button {
                    GlossLink.open(term: term, context: context, sourceTitle: workTitle)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle.magnifyingglass").font(.caption2)
                        Text("Open in Gloss").font(.caption.weight(.medium))
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.forward").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(pal.accent)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    GlossLink.openWebsite()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle.magnifyingglass").font(.caption2)
                        Text("Go deeper with Gloss").font(.caption.weight(.medium))
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").font(.system(size: 9))
                    }
                    .foregroundColor(pal.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Opens the word in the sibling SDIT app, Gloss — trying its URL scheme first and
// falling back to the web. The personal vocabulary layer is shared across SDIT apps
// (BIBLE §8): a word looked up here is there to study in Gloss.
enum GlossLink {
    // Hands the word to Gloss *with the passage it sits in* (`context`) and the book
    // it came from (`sourceTitle`), so Gloss can explain the word as it's used here —
    // Homer's "wrath," not the dictionary's. Long segments are trimmed to keep the URL
    // sane; Gloss only needs enough surrounding text to disambiguate.
    static func open(term: String, context: String? = nil, sourceTitle: String? = nil) {
        var comps = URLComponents()
        comps.scheme = "gloss"
        comps.host = "define"
        var items = [URLQueryItem(name: "term", value: term)]
        if let context = context?.trimmingCharacters(in: .whitespacesAndNewlines), !context.isEmpty {
            items.append(URLQueryItem(name: "context", value: String(context.prefix(1000))))
        }
        if let sourceTitle, !sourceTitle.isEmpty {
            items.append(URLQueryItem(name: "title", value: sourceTitle))
        }
        comps.queryItems = items
        guard let scheme = comps.url else { return }

        let q = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let web = URL(string: "https://sandiegotech.org/gloss?q=\(q)")
        UIApplication.shared.open(scheme, options: [:]) { opened in
            if !opened, let web { UIApplication.shared.open(web) }
        }
    }

    // When Gloss isn't installed: open its page so the reader can discover/get it.
    static func openWebsite() {
        if let url = URL(string: "https://sandiegotech.org/gloss") {
            UIApplication.shared.open(url)
        }
    }
}
