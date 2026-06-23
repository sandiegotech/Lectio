import Foundation

// The unified SDIT account & cross-app sync seam.
//
// One SDIT account works across every SDIT app (Lectio, Gloss, …). A person's
// personal layer — the words, highlights, notes, and reading places they collect —
// belongs to the *account*, not to any single app, and syncs everywhere. A word you
// save in Lectio is there to study in Gloss; a note you take in one app is yours in all.
//
// v1 is local-only: there is no account yet, so `LocalSyncProvider` is a no-op and the
// data lives on-device (SavedStore, ReadingState → UserDefaults). When the SDIT account
// ships, a cloud-backed provider plugs in *here* and nothing above this seam changes.
// This mirrors the AI capability seam (pipeline/ai/provider.py): route through the seam,
// never call a backend directly.
//
// The account "library" — what syncs:
//   • Saved words        (SavedWord)        — the shared vocabulary layer with Gloss
//   • Highlights         (SavedHighlight)
//   • Reading positions  (per-work resume point + bookmark, ReadingState)
//   • Notes              (future)
//
// Privacy posture ("The Compact"): the personal layer is the reader's. Sync is opt-in,
// scoped to the account, and never sold or mined.

enum SyncDomain {
    case savedWords
    case highlights
    case readingState
    case collection
}

protocol SyncProvider: AnyObject {
    /// An SDIT account is signed in and syncing.
    var isConnected: Bool { get }
    /// Local data in `domain` changed — push it when connected.
    func localDidChange(_ domain: SyncDomain)
}

/// v1 default: everything stays on-device. No account, no network.
final class LocalSyncProvider: SyncProvider {
    var isConnected: Bool { false }
    func localDidChange(_ domain: SyncDomain) {}
}

/// The single place the app reads/sets the active provider. Swap `provider` for a
/// cloud-backed SDITAccountProvider once the unified account exists; the stores above
/// already report their changes through here.
final class SyncCoordinator {
    static let shared = SyncCoordinator()
    var provider: SyncProvider = LocalSyncProvider()
    private init() {}

    func localDidChange(_ domain: SyncDomain) {
        provider.localDidChange(domain)
    }
}
