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
                        .background(GeometryReader { g in
                            Color.clear.preference(key: TokenFrameKey.self,
                                                   value: [i: g.frame(in: .named(space))])
                        })
                        .contentShape(Rectangle())
                        // Per-token tap + long-press ONLY — no drag gesture anywhere, so the
                        // ScrollView always keeps the pan and the text scrolls freely.
                        // Tap dismisses/syncs; a deliberate hold looks the word up.
                        .onTapGesture { onTap() }
                        .onLongPressGesture(minimumDuration: 0.22) { define(i) }
                }
            }
        }
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

    // Press-and-hold a word to look it up. (A plain long-press gesture never competes
    // with the ScrollView's pan, so the text scrolls freely.)
    private func define(_ i: Int) {
        let w = norm(i)
        if !w.isEmpty { onWord(w, center(i)) }
    }

    // MARK: appearance

    private func underlineColor(_ i: Int) -> Color? {
        let w = norm(i)
        if let d = definedWord, !d.isEmpty, w == d { return pal.accent }
        return nil
    }

    @ViewBuilder
    private func tokenHighlight(_ i: Int) -> some View {
        let inActive = activeRange?.contains(i) ?? false
        let inSaved = savedRanges.contains { $0.contains(i) }
        let isFocus = (focusWord != nil) && norm(i) == focusWord
        // A saved word gets a soft gold highlight wherever it appears in the text.
        let w = norm(i)
        let isSavedWord = !w.isEmpty && savedWords.contains(w)
        if inActive {
            Rectangle().fill(pal.accent.opacity(op(0.22, 0.16)))
        } else if inSaved {
            Rectangle().fill(pal.gold.opacity(op(0.30, 0.18)))
        } else if isSavedWord {
            Rectangle().fill(pal.gold.opacity(op(0.22, 0.15)))
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
                Button {
                    GlossLink.open(term: term, context: context, sourceTitle: workTitle)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle.magnifyingglass").font(.caption2)
                        Text("Open in Gloss").font(.caption.weight(.semibold))
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.forward").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(pal.accent))
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
