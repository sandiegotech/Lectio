import Foundation
import Combine

struct SavedWord: Codable, Identifiable, Hashable {
    var term: String
    var definition: String
    var workTitle: String?
    var workId: String?
    var id: String { term.lowercased() }
}

// A highlighted range of words inside one segment (paragraph). Anchored by token
// indices so it can be re-rendered in place, with the text kept for the Marks list.
struct SavedHighlight: Codable, Identifiable, Hashable {
    var id: String          // "<segmentId>#<start>-<end>"
    var segmentId: String
    var start: Int
    var end: Int
    var text: String
    var note: String?       // the reader's own thought, attached to the highlight
    var workTitle: String?
    var workId: String?

    var range: ClosedRange<Int> { start...max(start, end) }

    init(segmentId: String, start: Int, end: Int, text: String,
         note: String? = nil, workTitle: String? = nil, workId: String? = nil) {
        let lo = min(start, end), hi = max(start, end)
        self.id = "\(segmentId)#\(lo)-\(hi)"
        self.segmentId = segmentId
        self.start = lo
        self.end = hi
        self.text = text
        self.note = note
        self.workTitle = workTitle
        self.workId = workId
    }
}

// A book the reader has checked out into My Collection — saved to read or explore later.
struct SavedBook: Codable, Identifiable, Hashable {
    var title: String
    var author: String
    var id: String { title }
}

// Persists the reader's personal layer — saved words, highlights, and My Collection.
// Storage is iCloud-backed (CloudStore: UserDefaults + NSUbiquitousKeyValueStore) so it
// follows the reader across their devices; changes are also reported through the SDIT
// account sync seam (AccountSync.swift) for cross-app sync once the unified account ships.
final class SavedStore: ObservableObject {
    @Published private(set) var items: [SavedWord] = []
    @Published private(set) var highlights: [SavedHighlight] = []
    @Published private(set) var collection: [SavedBook] = []
    private let key = "savedWords.v1"
    private let highlightKey = "savedHighlights.v1"
    private let collectionKey = "myCollection.v1"

    init() {
        load()
        NotificationCenter.default.addObserver(forName: CloudStore.didChangeExternally,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.load()
        }
    }

    // MARK: My Collection

    func isInCollection(_ title: String) -> Bool {
        collection.contains { $0.id == title }
    }

    func toggleCollection(_ book: SavedBook) {
        if let i = collection.firstIndex(where: { $0.id == book.id }) {
            collection.remove(at: i)
        } else {
            collection.insert(book, at: 0)
        }
        saveCollection()
    }

    // MARK: words

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

    func words(forWork workId: String) -> [SavedWord] {
        items.filter { $0.workId == workId }
    }

    // MARK: highlights

    func addHighlight(_ h: SavedHighlight) {
        guard !highlights.contains(where: { $0.id == h.id }) else { return }
        highlights.insert(h, at: 0)
        save()
    }

    func removeHighlight(id: String) {
        highlights.removeAll { $0.id == id }
        save()
    }

    func highlight(id: String) -> SavedHighlight? {
        highlights.first { $0.id == id }
    }

    // Attach (or clear, with nil/empty) the reader's note on a highlight.
    func setNote(_ note: String?, forHighlight id: String) {
        guard let i = highlights.firstIndex(where: { $0.id == id }) else { return }
        let clean = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        highlights[i].note = (clean?.isEmpty ?? true) ? nil : clean
        save()
    }

    func highlights(forWork workId: String) -> [SavedHighlight] {
        highlights.filter { $0.workId == workId }
    }

    func ranges(forSegment segmentId: String) -> [ClosedRange<Int>] {
        highlights.filter { $0.segmentId == segmentId }.map(\.range)
    }

    // MARK: persistence

    private func load() {
        if let data = CloudStore.shared.data(forKey: key),
           let decoded = try? JSONDecoder().decode([SavedWord].self, from: data) {
            items = decoded
        }
        if let data = CloudStore.shared.data(forKey: highlightKey),
           let decoded = try? JSONDecoder().decode([SavedHighlight].self, from: data) {
            highlights = decoded
        }
        if let data = CloudStore.shared.data(forKey: collectionKey),
           let decoded = try? JSONDecoder().decode([SavedBook].self, from: data) {
            collection = decoded
        }
    }

    private func saveCollection() {
        if let data = try? JSONEncoder().encode(collection) {
            CloudStore.shared.set(data, forKey: collectionKey)
        }
        SyncCoordinator.shared.localDidChange(.collection)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            CloudStore.shared.set(data, forKey: key)
        }
        if let data = try? JSONEncoder().encode(highlights) {
            CloudStore.shared.set(data, forKey: highlightKey)
        }
        SyncCoordinator.shared.localDidChange(.savedWords)
        SyncCoordinator.shared.localDidChange(.highlights)
    }
}
