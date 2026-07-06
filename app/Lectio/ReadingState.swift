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
    var bookmarkSegmentId: String?   // an explicit place the reader dropped a bookmark
    var lastReadAt: Date?      // when the reader last put the book down (drives Continue reading)
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

    func bookmark(_ workId: String) -> String? { byWork[workId]?.bookmarkSegmentId }

    func setBookmark(_ workId: String, segmentId: String?) {
        var s = byWork[workId] ?? WorkReadingState()
        s.bookmarkSegmentId = segmentId
        byWork[workId] = s
        save()
    }

    func savePosition(workId: String, editionId: String?, sectionId: String?, segmentId: String?) {
        var s = byWork[workId] ?? WorkReadingState()
        s.editionId = editionId
        s.sectionId = sectionId
        s.segmentId = segmentId
        s.lastReadAt = Date()
        byWork[workId] = s
        save()
    }

    // The book most recently put down — the "pick up where you left off" pointer.
    var mostRecentWorkId: String? {
        byWork.compactMap { key, st in st.lastReadAt.map { (key, $0) } }
            .max { $0.1 < $1.1 }?.0
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
