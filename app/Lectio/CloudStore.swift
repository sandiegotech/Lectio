import Foundation

// The personal layer's storage: UserDefaults on the device, mirrored to iCloud key–value
// storage so saved words, highlights and reading places follow the reader to their other
// devices. It degrades to local-only when iCloud is unavailable (an unsigned simulator
// build, or a device not signed into iCloud).
//
// The local copy is authoritative. Reads never consult iCloud, except to seed a key this
// device has never written. A cloud value replaces the local one only when it arrives
// through the external-change notification AND carries a newer modified time than the
// local write. iCloud KVS caps out at 1 MB in total, so a write that would not fit is
// kept local and simply not mirrored; it can never cost the reader local data.
final class CloudStore {
    static let shared = CloudStore()
    static let didChangeExternally = Notification.Name("CloudStoreDidChangeExternally")

    private let kv = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard
    private let modifiedKey = "cloudStore.modified.v1"     // local: [key: seconds since 1970]
    private let kvBudget = 1_000_000 - 64_000                // KVS total quota, less headroom

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(externalChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: kv)
        kv.synchronize()
    }

    private static func stampKey(_ key: String) -> String { key + ".modified" }

    private func localModified(_ key: String) -> Double {
        (local.dictionary(forKey: modifiedKey)?[key] as? Double) ?? 0
    }

    private func setLocalModified(_ key: String, _ t: Double) {
        var all = local.dictionary(forKey: modifiedKey) ?? [:]
        all[key] = t
        local.set(all, forKey: modifiedKey)
    }

    func data(forKey key: String) -> Data? {
        if let d = local.data(forKey: key) { return d }
        // Never written here (a fresh install): seed from iCloud, nothing local to lose.
        guard let d = kv.data(forKey: key) else { return nil }
        local.set(d, forKey: key)
        setLocalModified(key, kv.double(forKey: Self.stampKey(key)))
        return d
    }

    func set(_ value: Data, forKey key: String) {
        let now = Date().timeIntervalSince1970
        local.set(value, forKey: key)
        setLocalModified(key, now)

        // Mirror to iCloud only if the whole store stays under the quota.
        let others = kv.dictionaryRepresentation.reduce(0) { sum, kvp in
            kvp.key == key ? sum : sum + ((kvp.value as? Data)?.count ?? 16)
        }
        guard others + value.count <= kvBudget else { return }
        kv.set(value, forKey: key)
        kv.set(now, forKey: Self.stampKey(key))
        kv.synchronize()
    }

    // Another device changed the personal layer: adopt each value that is newer than
    // the local write, then let the stores reload and republish.
    @objc private func externalChange(_ note: Notification) {
        let reason = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
        guard reason != NSUbiquitousKeyValueStoreQuotaViolationChange,
              let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
        var changed = false
        for k in keys where !k.hasSuffix(".modified") {
            guard let d = kv.data(forKey: k) else { continue }
            let cloudTime = kv.double(forKey: Self.stampKey(k))
            guard local.data(forKey: k) == nil || cloudTime > localModified(k) else { continue }
            local.set(d, forKey: k)
            setLocalModified(k, cloudTime)
            changed = true
        }
        if changed {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.didChangeExternally, object: nil)
            }
        }
    }
}
