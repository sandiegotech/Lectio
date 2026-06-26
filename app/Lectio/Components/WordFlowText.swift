import SwiftUI
import UIKit

// Collects each token's frame (in global space) so taps and drags can be mapped to words.
struct TokenFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// Renders a paragraph as individually laid-out words so the reader can:
//   • press & hold a word      → look it up (definition popup anchored at the word)
//   • press, hold, then drag   → select an exact span of words to highlight & save
//   • tap                      → dismiss an open popup (or sync the compare column)
// A long-press gates the drag, so ordinary scrolling still works anywhere over the text —
// a quick swipe scrolls; only a deliberate hold begins a definition or a selection.
struct WordFlowText: View {
    // Holds token frames without triggering a re-render (used to anchor popups & map drags).
    final class FrameBox { var frames: [Int: CGRect] = [:] }

    let text: String
    let pal: Palette
    var space: String = "reader"
    var definedWord: String? = nil
    var focusWord: String? = nil          // a saved word jumped-to from the panel: lightly highlighted
    var savedWords: Set<String> = []      // saved words: a light underline wherever they appear
    var savedRanges: [ClosedRange<Int>] = []
    var activeRange: ClosedRange<Int>? = nil
    var onWord: (String, CGPoint) -> Void = { _, _ in }
    var onSelectCommit: (ClosedRange<Int>, String, CGPoint) -> Void = { _, _, _ in }
    var onTap: () -> Void = {}

    @State private var box = FrameBox()
    @State private var dragSel: ClosedRange<Int>? = nil   // live span while dragging a selection
    @Environment(\.colorScheme) private var scheme
    private let selectDelay = 0.33   // hold this long before a define/select begins (scroll stays free)

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: 7) {
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
                        .background(GeometryReader { g in
                            Color.clear.preference(key: TokenFrameKey.self,
                                                   value: [i: g.frame(in: .named(space))])
                        })
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        // Simultaneous (not .gesture): an attached drag gesture otherwise eats the
        // ScrollView's pan, so the text wouldn't scroll. This way a quick swipe scrolls;
        // only a deliberate hold (then optional drag) defines/selects.
        .simultaneousGesture(selectGesture)
        .onPreferenceChange(TokenFrameKey.self) { box.frames = $0 }
    }

    // Word tokens (each keeps its trailing space), with a "\n" marker wherever the
    // source text breaks a line — so verse keeps its lines while prose flows normally.
    private var tokens: [String] {
        var out: [String] = []
        for (li, line) in text.components(separatedBy: "\n").enumerated() {
            if li > 0 { out.append("\n") }
            for w in line.split(separator: " ", omittingEmptySubsequences: true) {
                out.append(String(w) + " ")
            }
        }
        return out
    }

    private func norm(_ i: Int) -> String { WordDictionary.normalize(tokens[i]) }

    private func center(_ i: Int) -> CGPoint {
        let f = box.frames[i] ?? .zero
        return CGPoint(x: f.midX, y: f.midY)
    }

    // Dark mode washes the reading text out under a solid tint — keep highlights lighter at night.
    private func op(_ light: Double, _ dark: Double) -> Double { scheme == .dark ? dark : light }

    // MARK: interactions

    // Hold to begin; then lifting in place defines the word under the finger, while
    // dragging selects the exact span you sweep across (committed on release to save).
    private var selectGesture: some Gesture {
        LongPressGesture(minimumDuration: selectDelay)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(space)))
            .onChanged { value in
                guard case .second(true, let drag?) = value,
                      let a = tokenIndex(at: drag.startLocation),
                      let b = tokenIndex(at: drag.location) else { return }
                dragSel = min(a, b)...max(a, b)
            }
            .onEnded { value in
                defer { dragSel = nil }
                guard case .second(true, let drag?) = value,
                      let a = tokenIndex(at: drag.startLocation),
                      let b = tokenIndex(at: drag.location) else { return }
                let lo = min(a, b), hi = max(a, b)
                let moved = lo != hi || hypot(drag.translation.width, drag.translation.height) > 10
                if moved {
                    onSelectCommit(lo...hi, selectedText(lo...hi), center(hi))
                } else {
                    let w = norm(a)
                    if !w.isEmpty { onWord(w, center(a)) }
                }
            }
    }

    // Map a point (in `space` coordinates) to the token under it, or the nearest word —
    // so a drag that strays between/below words still resolves to a sensible boundary.
    private func tokenIndex(at p: CGPoint) -> Int? {
        if let hit = box.frames.first(where: {
            tokens.indices.contains($0.key) && tokens[$0.key] != "\n" && $0.value.contains(p)
        })?.key { return hit }
        var best: Int? = nil; var bestD = CGFloat.greatestFiniteMagnitude
        for (i, f) in box.frames where tokens.indices.contains(i) && tokens[i] != "\n" {
            let dy = max(0, max(f.minY - p.y, p.y - f.maxY))
            let dx = max(0, max(f.minX - p.x, p.x - f.maxX))
            let d = dy * 1000 + dx   // weight rows first, then horizontal distance
            if d < bestD { bestD = d; best = i }
        }
        return best
    }

    // MARK: appearance

    private func underlineColor(_ i: Int) -> Color? {
        let w = norm(i)
        if let d = definedWord, !d.isEmpty, w == d { return pal.accent }
        if !w.isEmpty, savedWords.contains(w) { return pal.gold.opacity(op(0.7, 0.55)) }
        return nil
    }

    @ViewBuilder
    private func tokenHighlight(_ i: Int) -> some View {
        let inActive = (activeRange?.contains(i) ?? false) || (dragSel?.contains(i) ?? false)
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

    // Subtle bridge to the sibling app — prominent when the word is outside this
    // book's corpus, a quiet "study deeper" link when we already have a definition.
    private var glossLink: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().overlay(pal.rule)
            Button {
                GlossLink.open(term: term)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle.magnifyingglass").font(.caption2)
                    Text(hasDefinition ? "Study in Gloss" : "Look up “\(term)” in Gloss")
                        .font(.caption.weight(.medium))
                    Spacer(minLength: 0)
                    Text("powered by Gloss")
                        .font(.system(size: 8, weight: .regular)).tracking(0.3)
                        .foregroundColor(pal.inkSoft.opacity(0.7))
                }
                .foregroundColor(hasDefinition ? pal.inkSoft : pal.accent)
            }
            .buttonStyle(.plain)
        }
    }
}

// Opens the word in the sibling SDIT app, Gloss — trying its URL scheme first and
// falling back to the web. The personal vocabulary layer is shared across SDIT apps
// (BIBLE §8): a word looked up here is there to study in Gloss.
enum GlossLink {
    static func open(term: String) {
        let q = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        guard let scheme = URL(string: "gloss://define?term=\(q)") else { return }
        let web = URL(string: "https://sandiegotech.org/gloss?q=\(q)")
        UIApplication.shared.open(scheme, options: [:]) { opened in
            if !opened, let web { UIApplication.shared.open(web) }
        }
    }
}
