import Foundation
import Combine

// Per-work reading state: where the reader left off, and whether they've seen the
// book's introduction. Persisted in UserDefaults (small personal data; migrates to
// synced storage with accounts later, alongside SavedStore).
struct WorkReadingState: Codable, Hashable {
    var editionId: String?
    var sectionId: String?
    var segmentId: String?     // finer scroll anchor than the section
    var introSeen: Bool = false
    var bookmarkSegmentId: String?   // legacy single bookmark — folded into `bookmarks`
    var bookmarks: [String]? = nil   // dropped bookmarks, in the order they were placed
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

    func savePosition(workId: String, editionId: String?, sectionId: String?, segmentId: String?) {
        var s = byWork[workId] ?? WorkReadingState()
        s.editionId = editionId
        s.sectionId = sectionId
        s.segmentId = segmentId
        byWork[workId] = s
        save()
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
        SyncCoordinator.shared.localDidChange(.readingState)
    }
}
