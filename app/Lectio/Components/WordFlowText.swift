import SwiftUI
import UIKit

// Collects each token's frame (in global space) so taps and drags can be mapped to words.
struct TokenFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// Renders a paragraph as individually tappable words so the reader can:
//   • tap a word            → look it up (popup anchored at the word)
//   • press & hold a word   → highlight the sentence it's in, to save
// Both are per-token tap/long-press gestures (no continuous drag), so they never
// compete with the ScrollView — you can scroll anywhere over the text.
struct WordFlowText: View {
    // Holds token frames without triggering a re-render (used only to anchor the popup).
    final class FrameBox { var frames: [Int: CGRect] = [:] }

    let text: String
    let pal: Palette
    var space: String = "reader"
    var holdSeconds: Double = 0.8
    var definedWord: String? = nil
    var focusWord: String? = nil          // a saved word jumped-to from the panel: lightly highlighted
    var savedWords: Set<String> = []      // saved words: a light underline wherever they appear
    var savedRanges: [ClosedRange<Int>] = []
    var activeRange: ClosedRange<Int>? = nil
    var onWord: (String, CGPoint) -> Void = { _, _ in }
    var onSelectCommit: (ClosedRange<Int>, String, CGPoint) -> Void = { _, _, _ in }

    @State private var box = FrameBox()
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: 7) {
            ForEach(tokens.indices, id: \.self) { i in
                Text(tokens[i])
                    .font(.system(size: 19, design: .serif))
                    .foregroundColor(pal.ink)
                    .underline(underlineColor(i) != nil, color: underlineColor(i) ?? .clear)
                    .background(tokenHighlight(i))
                    .background(GeometryReader { g in
                        Color.clear.preference(key: TokenFrameKey.self,
                                               value: [i: g.frame(in: .named(space))])
                    })
                    .contentShape(Rectangle())
                    .onTapGesture { tap(i) }
                    .onLongPressGesture(minimumDuration: holdSeconds) { hold(i) }
            }
        }
        .onPreferenceChange(TokenFrameKey.self) { box.frames = $0 }
    }

    private var tokens: [String] {
        text.split(separator: " ", omittingEmptySubsequences: true).map { String($0) + " " }
    }

    private func norm(_ i: Int) -> String { WordDictionary.normalize(tokens[i]) }

    private func center(_ i: Int) -> CGPoint {
        let f = box.frames[i] ?? .zero
        return CGPoint(x: f.midX, y: f.midY)
    }

    // Dark mode washes the reading text out under a solid tint — keep highlights lighter at night.
    private func op(_ light: Double, _ dark: Double) -> Double { scheme == .dark ? dark : light }

    // MARK: interactions

    private func tap(_ i: Int) {
        let w = norm(i)
        if !w.isEmpty { onWord(w, center(i)) }
    }

    private func hold(_ i: Int) {
        let r = sentenceRange(around: i)
        onSelectCommit(r, selectedText(r), center(i))
    }

    // The token range of the sentence containing token i.
    private func sentenceRange(around i: Int) -> ClosedRange<Int> {
        var lo = i
        while lo > 0 && !endsSentence(tokens[lo - 1]) { lo -= 1 }
        var hi = i
        while hi < tokens.count - 1 && !endsSentence(tokens[hi]) { hi += 1 }
        return lo...hi
    }

    private func endsSentence(_ token: String) -> Bool {
        let s = token.trimmingCharacters(in: .whitespaces)
        guard let last = s.last else { return false }
        if ".!?".contains(last) { return true }
        // also handle a closing quote after terminal punctuation: ." ?" !”
        return s.count >= 2 && "”\"’'".contains(last) && ".!?".contains(s[s.index(s.endIndex, offsetBy: -2)])
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
    let workTitle: String?
    let workId: String?
    let pal: Palette
    let onClose: () -> Void
    @EnvironmentObject var saved: SavedStore

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
