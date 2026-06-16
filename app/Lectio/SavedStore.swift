import Foundation
import Combine

struct SavedWord: Codable, Identifiable, Hashable {
    var term: String
    var definition: String
    var workTitle: String?
    var id: String { term.lowercased() }
}

struct SavedPassage: Codable, Identifiable, Hashable {
    var id: String          // segment id
    var text: String
    var workTitle: String?
}

// Persists words and passages the reader saves while reading.
// Stored in UserDefaults (a small personal list); migrates to synced storage later.
final class SavedStore: ObservableObject {
    @Published private(set) var items: [SavedWord] = []
    @Published private(set) var passages: [SavedPassage] = []
    private let key = "savedWords.v1"
    private let passageKey = "savedPassages.v1"

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

    // MARK: passages

    func isPassageSaved(_ id: String) -> Bool {
        passages.contains { $0.id == id }
    }

    func togglePassage(_ passage: SavedPassage) {
        if let i = passages.firstIndex(where: { $0.id == passage.id }) {
            passages.remove(at: i)
        } else {
            passages.insert(passage, at: 0)
        }
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([SavedWord].self, from: data) {
            items = decoded
        }
        if let data = UserDefaults.standard.data(forKey: passageKey),
           let decoded = try? JSONDecoder().decode([SavedPassage].self, from: data) {
            passages = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
        if let data = try? JSONEncoder().encode(passages) {
            UserDefaults.standard.set(data, forKey: passageKey)
        }
    }
}
