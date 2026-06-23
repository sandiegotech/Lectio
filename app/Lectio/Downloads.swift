import Foundation

// Where a book's content comes from.
//
// Today every book ships inside the app bundle, so content is already on-device and
// "downloading" completes instantly. When the catalog outgrows a bundled app, a remote
// source (Cloudflare R2 — free egress) plugs in HERE: the app ships tiny and fetches each
// book's text + cover on checkout. Nothing above this seam changes. Mirrors the AI
// capability seam (pipeline/ai/provider.py) and the AccountSync seam.
protocol ContentSource {
    // Ensure the work's content is available on-device. Returns whether it's ready.
    func ensureAvailable(workId: String?) async -> Bool
}

// v1 (current model): the ingested ("working") works ship in the app bundle and are on the
// tablet; coming-soon shells (no `workId`) are simulated as being "in the cloud" — their full
// descriptions are bundled, but there's no book text to read yet. So availability today is
// simply: real work → on device, shell → in the cloud. When the remote source ships, this
// becomes a real fetch and only checked-out books live on-device.
struct BundledContentSource: ContentSource {
    func ensureAvailable(workId: String?) async -> Bool { workId != nil }
}

// "Checked out = downloaded." Tracks which books are on THIS device. Note the split:
// My Collection (the *intent* — which books you want) syncs across devices via iCloud,
// while downloads (the *bytes*) are device-local. Check out on one device → it syncs as
// intent → each device downloads it locally.
@MainActor
final class Downloads: ObservableObject {
    enum State { case notDownloaded, downloading, downloaded }

    @Published private(set) var downloaded: Set<String> = []   // by book title
    @Published private(set) var inFlight: Set<String> = []
    private let key = "downloads.v1"
    var source: ContentSource = BundledContentSource()

    init() { load() }

    func state(_ title: String) -> State {
        if downloaded.contains(title) { return .downloaded }
        if inFlight.contains(title) { return .downloading }
        return .notDownloaded
    }

    func ensure(title: String, workId: String?) {
        guard !downloaded.contains(title), !inFlight.contains(title) else { return }
        inFlight.insert(title)
        Task {
            let ok = await source.ensureAvailable(workId: workId)
            inFlight.remove(title)
            if ok { downloaded.insert(title); save() }
        }
    }

    func remove(title: String) {
        guard downloaded.remove(title) != nil else { return }
        save()
    }

    // Make on-device downloads match the (synced) collection: download anything checked out
    // that isn't here yet, and drop anything no longer in the collection.
    func reconcile(with collection: [SavedBook]) {
        let wanted = Set(collection.map { $0.title })
        for b in collection { ensure(title: b.title, workId: nil) }
        for t in downloaded.subtracting(wanted) { remove(title: t) }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let set = try? JSONDecoder().decode(Set<String>.self, from: data) {
            downloaded = set
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(downloaded) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
