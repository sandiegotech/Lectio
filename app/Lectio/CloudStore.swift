import Foundation

// The personal layer's storage, backed by iCloud key–value sync.
//
// Writes go to BOTH UserDefaults (instant, local) and NSUbiquitousKeyValueStore (iCloud),
// so saved words, highlights, reading places, and My Collection follow the reader across
// their own devices via their Apple ID. It degrades to local-only when iCloud is
// unavailable (an unsigned simulator build, or a device not signed into iCloud).
//
// iCloud KVS fits the personal layer well: small key–value data, far under its 1 MB /
// 1024-key limit. The cross-app SDIT account (AccountSync seam) layers on top later for
// app-to-app sync; this handles same-user, device-to-device today.
final class CloudStore {
    static let shared = CloudStore()
    static let didChangeExternally = Notification.Name("CloudStoreDidChangeExternally")

    private let kv = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(externalChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: kv)
        kv.synchronize()
    }

    func data(forKey key: String) -> Data? {
        kv.data(forKey: key) ?? local.data(forKey: key)
    }

    func set(_ value: Data, forKey key: String) {
        local.set(value, forKey: key)
        kv.set(value, forKey: key)
        kv.synchronize()
    }

    // Another device changed the personal layer — mirror iCloud down into the local cache
    // so reads stay consistent, then let the stores reload and republish.
    @objc private func externalChange(_ note: Notification) {
        if let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
            for k in keys where kv.data(forKey: k) != nil {
                local.set(kv.data(forKey: k), forKey: k)
            }
        }
        NotificationCenter.default.post(name: Self.didChangeExternally, object: nil)
    }
}
