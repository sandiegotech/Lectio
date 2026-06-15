import Foundation
import Combine

// Tap-to-define lookup. Backed by a bundled public-domain dictionary
// (content/dictionary/webster-1913.json, currently a seed set). Returns nil when a
// word isn't covered — the full Webster's 1913 ingest is a later content task.
final class WordDictionary: ObservableObject {
    private var entries: [String: String] = [:]

    init() { load() }

    private func load() {
        guard let url = Bundle.main.url(forResource: "webster-1913", withExtension: "json",
                                        subdirectory: "content/dictionary"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return }
        for (term, def) in dict { entries[term.lowercased()] = def }
    }

    func define(_ word: String) -> String? {
        entries[WordDictionary.normalize(word)]
    }

    var count: Int { entries.count }

    // Lowercase, strip surrounding punctuation/quotes — but keep internal hyphens/apostrophes.
    static func normalize(_ word: String) -> String {
        word.lowercased().trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "-'"))
        )
    }
}
