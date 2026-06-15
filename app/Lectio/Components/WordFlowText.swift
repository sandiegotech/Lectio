import SwiftUI

// Renders a paragraph as individually tappable words so a reader can select one and
// explore it. Each token carries its trailing space, so horizontal spacing is 0 and
// FlowLayout only adds vertical line spacing.
struct WordFlowText: View {
    let text: String
    let pal: Palette
    var highlight: String? = nil
    let onSelect: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: 7) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                Text(token)
                    .font(.system(size: 19, design: .serif))
                    .foregroundColor(pal.ink)
                    .underline(isHighlighted(token), color: pal.accent)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.3) {
                        let word = WordDictionary.normalize(token)
                        if !word.isEmpty { onSelect(word) }
                    }
            }
        }
    }

    private var tokens: [String] {
        text.split(separator: " ", omittingEmptySubsequences: true).map { String($0) + " " }
    }

    private func isHighlighted(_ token: String) -> Bool {
        guard let h = highlight else { return false }
        return WordDictionary.normalize(token) == h
    }
}

// Word/phrase detail card — used in the narrow-width sheet (the rail shows its own
// inline version when there's room).
struct WordDetail: View {
    let term: String
    let definition: String?
    let workTitle: String?
    let pal: Palette
    @EnvironmentObject var saved: SavedStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(term)
                .font(.system(.title2, design: .serif))
                .foregroundColor(pal.accent)
            if let def = definition {
                Text(def).font(.system(.body, design: .serif)).foregroundColor(pal.ink)
            } else {
                Text("No definition yet — the full Webster's 1913 dictionary isn't ingested. You can still save this word.")
                    .font(.footnote).foregroundColor(pal.inkSoft)
            }
            Button {
                saved.toggle(SavedWord(term: term, definition: definition ?? "", workTitle: workTitle))
            } label: {
                Label(saved.isSaved(term) ? "Saved" : "Save word",
                      systemImage: saved.isSaved(term) ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.bordered)
            .tint(pal.accent)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(pal.paper)
    }
}
