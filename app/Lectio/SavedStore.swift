import Foundation
import Combine

struct SavedWord: Codable, Identifiable, Hashable {
    var term: String
    var definition: String
    var workTitle: String?
    var workId: String?
    // One entry per book: the same word saved in two books is two entries. Computed, so
    // entries stored under the old term-only key carry over unchanged.
    var id: String { SavedWord.key(term, workId) }
    static func key(_ term: String, _ workId: String?) -> String { (workId ?? "") + "|" + term.lowercased() }
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

// Persists the reader's personal layer — saved words and highlights (with their notes).
// Storage is CloudStore: local first, mirrored to iCloud key–value storage.
final class SavedStore: ObservableObject {
    @Published private(set) var items: [SavedWord] = []
    @Published private(set) var highlights: [SavedHighlight] = []
    private let key = "savedWords.v1"
    private let highlightKey = "savedHighlights.v1"

    init() {
        load()
        NotificationCenter.default.addObserver(forName: CloudStore.didChangeExternally,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.load()
        }
    }

    // MARK: words

    func isSaved(_ term: String, workId: String?) -> Bool {
        let k = SavedWord.key(term, workId)
        return items.contains { $0.id == k }
    }

    func toggle(_ word: SavedWord) {
        if let i = items.firstIndex(where: { $0.id == word.id }) {
            items.remove(at: i)
        } else {
            items.insert(word, at: 0)
        }
        save()
    }

    func remove(_ word: SavedWord) {
        items.removeAll { $0.id == word.id }
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
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            CloudStore.shared.set(data, forKey: key)
        }
        if let data = try? JSONEncoder().encode(highlights) {
            CloudStore.shared.set(data, forKey: highlightKey)
        }
    }
}
