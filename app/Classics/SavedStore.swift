import Foundation
import Combine

struct SavedWord: Codable, Identifiable, Hashable {
    var term: String
    var definition: String
    var workTitle: String?
    var id: String { term.lowercased() }
}

// Persists words/phrases the reader saves while exploring, with their description.
// Stored in UserDefaults (a small personal list); migrates to synced storage later.
final class SavedStore: ObservableObject {
    @Published private(set) var items: [SavedWord] = []
    private let key = "savedWords.v1"

    init() { load() }

    func isSaved(_ term: String) -> Bool {
        items.contains { $0.id == term.lowercased() }
    }

    func toggle(_ word: SavedWord) {
        if let i = items.firstIndex(where: { $0.id == word.id }) {
            items.remove(at: i)
        } else {
            items.insert(word, at: 0)
        }
        save()
    }

    func remove(_ term: String) {
        items.removeAll { $0.id == term.lowercased() }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedWord].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
