import SwiftUI
import UIKit

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
                        // Frames go straight into the box (a plain class) — routing
                        // them through the preference system made every layout pass
                        // merge per-token dictionaries and froze panel transitions.
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .named(space))
                        } action: { frame in
                            box.frames[i] = frame
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { tap(i) }
                        .onLongPressGesture(minimumDuration: holdSeconds) { hold(i) }
                }
            }
        }
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
    var conceptId: String? = nil      // links to a shared Concept node, if any
    let workTitle: String?
    let workId: String?
    // The on-device model's quick in-context definition — streamed straight into
    // the bubble when the word isn't in the curated glossary.
    var defineStream: (() -> AsyncThrowingStream<String, Error>?)? = nil
    var onAsk: (() -> Void)? = nil    // go deeper: opens the Docent conversation
    let pal: Palette
    let onClose: () -> Void
    @EnvironmentObject var saved: SavedStore
    @EnvironmentObject var library: Library

    @State private var aiDef = ""
    @State private var aiFailed = false
    @State private var defineTask: Task<Void, Never>?

    private var concept: Concept? { conceptId.flatMap { library.concept(id: $0) } }
    private var hasDefinition: Bool { (definition?.isEmpty == false) }
    // Last resort: Apple's dictionary, only when neither the curated glossary nor
    // the on-device model can say anything.
    private var systemHasDefinition: Bool {
        !hasDefinition && defineStream == nil && SystemDictionary.hasDefinition(term)
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
            } else if defineStream != nil {
                if aiDef.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small).tint(pal.inkSoft)
                        Text("Reading the passage…").font(.caption).foregroundColor(pal.inkSoft)
                    }
                } else {
                    Text(aiDef).font(.system(.footnote, design: .serif))
                        .foregroundColor(aiFailed ? pal.inkSoft : pal.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("On-device AI · may err")
                        .font(.system(size: 8)).tracking(0.3)
                        .foregroundColor(pal.inkSoft.opacity(0.7))
                }
            } else {
                Text(systemHasDefinition
                     ? "Not in this book's glossary — try the dictionary."
                     : "Not in this book's glossary. Save it for study.")
                    .font(.caption).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let concept { conceptBlock(concept) }
            FlowLayout(spacing: 6) {
                Button {
                    saved.toggle(SavedWord(term: term, definition: definition ?? aiDef,
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
                if let onAsk {
                    Button(action: onAsk) {
                        Label("Explore", systemImage: "questionmark.bubble")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .foregroundColor(pal.accent)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(pal.rule))
                    }
                    .buttonStyle(.plain)
                }
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
        }
        .padding(14)
        .frame(width: 260)
        .background(RoundedRectangle(cornerRadius: 12).fill(pal.paper))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.rule))
        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
        .onAppear { startDefining() }
        .onDisappear { defineTask?.cancel() }
    }

    // Stream the model's quick definition into the bubble (uncurated words only).
    private func startDefining() {
        guard !hasDefinition, let make = defineStream, let stream = make() else { return }
        defineTask = Task {
            do {
                for try await text in stream {
                    guard !Task.isCancelled else { return }
                    aiDef = text
                }
            } catch {
                guard !Task.isCancelled, aiDef.isEmpty else { return }
                aiFailed = true
                aiDef = "Couldn't define this one — try Explore."
            }
        }
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

}
