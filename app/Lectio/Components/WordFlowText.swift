import SwiftUI
import UIKit

// The paragraph's own origin in the reader coordinate space — combined with the
// layout-local token frames FlowLayout reports, this maps touches to words with a
// single GeometryReader instead of one per token.
struct FlowOriginKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { value = nextValue() }
}

// Renders a paragraph as individually laid-out words. All touch handling is done by a
// single UIKit recognizer overlay (see TextInteractionOverlay) rather than per-word
// SwiftUI gestures — so:
//   • one-finger drag from ANYWHERE scrolls the page (the ScrollView's own pan, an
//     ancestor of this overlay, still receives every touch)
//   • hold a word            → that one word is selected; release shows its meaning
//   • keep holding and drag  → extend the selection across a phrase or sentence
//   • tap an existing highlight → open its note
// The old per-word gestures fought the ScrollView for the pan, which is why scrolling
// only worked in the margins; a UILongPressGestureRecognizer coexists with scroll the
// way Books and Kindle do.
struct WordFlowText: View {
    // Holds token frames without triggering a re-render. `local` frames come straight
    // from FlowLayout (paragraph-local space, same as the overlay's touch coordinates);
    // `origin` lifts a point into reader space for popup anchoring. `selAnchor` is the
    // word the current hold began on — kept here (a reference type) so the UIKit
    // callbacks can mutate it without going through @State.
    final class FrameBox {
        var local: [Int: CGRect] = [:]
        var origin: CGPoint = .zero
        var selAnchor: Int? = nil
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
    var onSelectDrag: (CGPoint) -> Void = { _ in }        // live drag point in reader space (edge auto-scroll)
    var onSelectCommit: (ClosedRange<Int>, String, CGPoint) -> Void = { _, _, _ in }
    var onSelectionActive: (Bool) -> Void = { _ in }      // true while a hold-select is in progress
    var onTapHighlight: (Int) -> Void = { _ in }          // tapped inside a saved highlight (token index)
    var onTap: () -> Void = {}

    // Tokenized once at creation — body indexes these hundreds of times per layout pass,
    // and recomputing the split on every access made each render O(n²).
    private let tokens: [String]
    private let normTokens: [String]

    @State private var box = FrameBox()
    @Environment(\.colorScheme) private var scheme

    init(text: String, pal: Palette, space: String = "reader",
         focusWord: String? = nil, savedWords: Set<String> = [],
         importantWords: Set<String> = [],
         savedRanges: [ClosedRange<Int>] = [], activeRange: ClosedRange<Int>? = nil,
         onSelectChange: @escaping (ClosedRange<Int>) -> Void = { _ in },
         onSelectDrag: @escaping (CGPoint) -> Void = { _ in },
         onSelectCommit: @escaping (ClosedRange<Int>, String, CGPoint) -> Void = { _, _, _ in },
         onSelectionActive: @escaping (Bool) -> Void = { _ in },
         onTapHighlight: @escaping (Int) -> Void = { _ in },
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
        self.onSelectionActive = onSelectionActive
        self.onTapHighlight = onTapHighlight
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
                }
            }
        }
        .background(GeometryReader { g in
            Color.clear.preference(key: FlowOriginKey.self,
                                   value: g.frame(in: .named(space)).origin)
        })
        .onPreferenceChange(FlowOriginKey.self) { [box] in box.origin = $0 }
        // The one recognizer layer. Points arrive in paragraph-local space (== box.local).
        .overlay(
            TextInteractionOverlay(
                onHoldBegan: { p in beginSelection(local: p) },
                onHoldChanged: { p in changeSelection(local: p) },
                onHoldEnded: { p in endSelection(local: p) },
                onTap: { p in tapAt(local: p) }
            )
        )
    }

    // MARK: touch → token

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

    // The token nearest a paragraph-local point — exact hit first, else the closest by
    // line (vertical distance weighted heavily so a drag past the margin stays on its line).
    private func tokenIndex(local p: CGPoint) -> Int? {
        var best: Int? = nil
        var bestDist = CGFloat.greatestFiniteMagnitude
        for (i, f) in box.local where tokens.indices.contains(i) && tokens[i] != "\n" {
            if f.contains(p) { return i }
            let dy = max(0, max(f.minY - p.y, p.y - f.maxY))
            let dx = max(0, max(f.minX - p.x, p.x - f.maxX))
            let d = dy * 8 + dx
            if d < bestDist { bestDist = d; best = i }
        }
        return best
    }

    private func readerPoint(local p: CGPoint) -> CGPoint {
        CGPoint(x: p.x + box.origin.x, y: p.y + box.origin.y)
    }

    // MARK: selection handlers (called by the UIKit overlay)

    private func beginSelection(local p: CGPoint) {
        guard let i = tokenIndex(local: p) else { return }
        box.selAnchor = i
        onSelectionActive(true)
        onSelectChange(i...i)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func changeSelection(local p: CGPoint) {
        guard let a = box.selAnchor, let i = tokenIndex(local: p) else { return }
        onSelectChange(min(a, i)...max(a, i))
        onSelectDrag(readerPoint(local: p))
    }

    private func endSelection(local p: CGPoint) {
        defer { box.selAnchor = nil; onSelectionActive(false) }
        guard let a = box.selAnchor else { return }
        let i = tokenIndex(local: p) ?? a
        let r = min(a, i)...max(a, i)
        onSelectCommit(r, selectedText(r), readerPoint(local: p))
    }

    private func tapAt(local p: CGPoint) {
        guard let i = tokenIndex(local: p) else { onTap(); return }
        if savedRanges.contains(where: { $0.contains(i) }) {
            onTapHighlight(i)
        } else {
            onTap()
        }
    }

    // MARK: appearance

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

// A transparent UIKit layer hosting a long-press + tap recognizer over the word text.
// It lives inside the ScrollView's content, so the scroll view's pan recognizer (an
// ancestor) still evaluates every touch: a quick one-finger drag scrolls the page from
// anywhere, while a deliberate 0.3s hold begins word selection. The long-press is NOT
// simultaneous with the pan (hold-still selects, move-first scrolls); the reader
// additionally disables scroll for the duration of a live selection.
private struct TextInteractionOverlay: UIViewRepresentable {
    var onHoldBegan: (CGPoint) -> Void
    var onHoldChanged: (CGPoint) -> Void
    var onHoldEnded: (CGPoint) -> Void
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        let hold = UILongPressGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.handleHold(_:)))
        hold.minimumPressDuration = 0.3
        hold.delegate = context.coordinator
        v.addGestureRecognizer(hold)
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        v.addGestureRecognizer(tap)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: TextInteractionOverlay
        init(_ parent: TextInteractionOverlay) { self.parent = parent }

        @objc func handleHold(_ g: UILongPressGestureRecognizer) {
            let p = g.location(in: g.view)
            switch g.state {
            case .began:  parent.onHoldBegan(p)
            case .changed: parent.onHoldChanged(p)
            case .ended, .cancelled, .failed: parent.onHoldEnded(p)
            default: break
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            parent.onTap(g.location(in: g.view))
        }

        // Let the tap coexist with everything; the hold is intentionally left
        // non-simultaneous so it and the scroll pan stay mutually exclusive.
        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            g is UITapGestureRecognizer || other is UITapGestureRecognizer
        }
    }
}
