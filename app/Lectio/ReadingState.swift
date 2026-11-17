import Foundation
import Combine

// Per-work reading state: where the reader left off, and whether they've seen the
// book's introduction. Persisted through CloudStore, alongside SavedStore.
struct WorkReadingState: Codable, Hashable {
    var editionId: String?
    var sectionId: String?
    var segmentId: String?     // finer scroll anchor than the section
    var introSeen: Bool = false
    var bookmarkSegmentId: String?   // legacy single bookmark — folded into `bookmarks`
    var bookmarks: [String]? = nil   // dropped bookmarks, in the order they were placed
    var lastReadAt: Date?      // when the reader last put the book down
    var lastOpenedAt: Date?    // when the reader last opened the book (orders My Books)
    var place: String?         // "Book IV  ·  37%", written with the position
    var progress: Double?      // 0...1 through the book, written with the position

    // In My Books: opened, or (from before lastOpenedAt existed) has a saved position.
    var isOpened: Bool { lastOpenedAt != nil || lastReadAt != nil || segmentId != nil }
    var recency: Date { lastOpenedAt ?? lastReadAt ?? .distantPast }
}

final class ReadingState: ObservableObject {
    @Published private(set) var byWork: [String: WorkReadingState] = [:]
    private let key = "readingState.v1"

    init() {
        load()
        NotificationCenter.default.addObserver(forName: CloudStore.didChangeExternally,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.load()
        }
    }

    func state(_ workId: String) -> WorkReadingState? { byWork[workId] }

    func introSeen(_ workId: String) -> Bool { byWork[workId]?.introSeen ?? false }

    func markIntroSeen(_ workId: String) {
        var s = byWork[workId] ?? WorkReadingState()
        guard !s.introSeen else { return }
        s.introSeen = true
        byWork[workId] = s
        save()
    }

    // All dropped bookmarks, oldest first (a legacy single bookmark shows up too).
    func bookmarks(_ workId: String) -> [String] {
        let s = byWork[workId]
        if let list = s?.bookmarks, !list.isEmpty { return list }
        return s?.bookmarkSegmentId.map { [$0] } ?? []
    }

    func isBookmarked(_ workId: String, segmentId: String) -> Bool {
        bookmarks(workId).contains(segmentId)
    }

    func toggleBookmark(_ workId: String, segmentId: String) {
        var s = byWork[workId] ?? WorkReadingState()
        var list = s.bookmarks ?? s.bookmarkSegmentId.map { [$0] } ?? []
        if let i = list.firstIndex(of: segmentId) { list.remove(at: i) }
        else { list.append(segmentId) }
        s.bookmarks = list
        s.bookmarkSegmentId = nil
        byWork[workId] = s
        save()
    }

    func markOpened(_ workId: String) {
        var s = byWork[workId] ?? WorkReadingState()
        s.lastOpenedAt = Date()
        byWork[workId] = s
        save()
    }

    // "Remove from My Books": forget the place and the opening, keep bookmarks and the rest.
    func removeFromMyBooks(_ workId: String) {
        guard var s = byWork[workId] else { return }
        s.editionId = nil; s.sectionId = nil; s.segmentId = nil
        s.lastReadAt = nil; s.lastOpenedAt = nil; s.place = nil; s.progress = nil
        byWork[workId] = s
        save()
    }

    func savePosition(workId: String, editionId: String?, sectionId: String?, segmentId: String?,
                      place: String?, progress: Double?) {
        var s = byWork[workId] ?? WorkReadingState()
        s.place = place
        s.progress = progress
        s.editionId = editionId
        s.sectionId = sectionId
        s.segmentId = segmentId
        s.lastReadAt = Date()
        byWork[workId] = s
        save()
    }

    // Positions saved before progress was recorded get it filled in once, off the main
    // thread (it needs the edition decoded), so their ribbons appear.
    func backfillProgress(using library: Library) {
        let missing = byWork.filter { $0.value.segmentId != nil && $0.value.progress == nil }
        guard !missing.isEmpty else { return }
        DispatchQueue.global(qos: .utility).async {
            var found: [String: (Double, String?)] = [:]
            for (wid, st) in missing {
                guard let eid = st.editionId, let ed = library.edition(eid),
                      let p = ed.progress(segmentId: st.segmentId) else { continue }
                found[wid] = (p, ed.place(sectionId: st.sectionId, progress: p))
            }
            DispatchQueue.main.async {
                for (wid, f) in found where self.byWork[wid]?.progress == nil {
                    self.byWork[wid]?.progress = f.0
                    self.byWork[wid]?.place = f.1
                }
                if !found.isEmpty { self.save() }
            }
        }
    }

    // My Books: every opened work, most recently opened first (ties by id, so stable).
    var openedWorkIds: [String] {
        byWork.filter { $0.value.isOpened }
            .sorted { a, b in a.value.recency != b.value.recency ? a.value.recency > b.value.recency : a.key < b.key }
            .map(\.key)
    }

    private func load() {
        if let data = CloudStore.shared.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: WorkReadingState].self, from: data) {
            byWork = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(byWork) {
            CloudStore.shared.set(data, forKey: key)
        }
    }
}

extension Edition {
    // How far through the book a segment sits (by reading order), 0...1.
    func progress(segmentId: String?) -> Double? {
        guard let segmentId else { return nil }
        let total = sections.reduce(0) { $0 + $1.segments.count }
        var n = 0
        for sec in sections {
            if let i = sec.segments.firstIndex(where: { $0.id == segmentId }) {
                return total > 0 ? Double(n + i + 1) / Double(total) : nil
            }
            n += sec.segments.count
        }
        return nil
    }

    // "Book IV  ·  37%" — the line under a book in My Books, computed when the position
    // is saved so the home screen never decodes an edition.
    func place(sectionId: String?, progress: Double?) -> String? {
        var parts: [String] = []
        if let sid = sectionId, let sec = sections.first(where: { $0.id == sid }), sections.count > 1 {
            parts.append(sec.label)
        }
        if let p = progress { parts.append(percentLabel(p)) }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }
}

// Mutated only on the main thread; the background progress backfill hops back to it.
extension ReadingState: @unchecked Sendable {}

// "37%"; a book just begun reads 1%, never 0%.
func percentLabel(_ p: Double) -> String { "\(min(100, max(1, Int((p * 100).rounded()))))%" }
