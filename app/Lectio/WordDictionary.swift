import Foundation
import UIKit

// Word-normalization used across tap-to-define, saved words, and the glossary index.
// (Generic dictionary lookups go through SystemDictionary, below — Lectio no longer
// bundles a dictionary; the curated glossary is tier 1, Apple's on-device dictionary
// is tier 2.)
enum WordDictionary {
    // Lowercase, strip surrounding punctuation/quotes — but keep internal hyphens/apostrophes.
    static func normalize(_ word: String) -> String {
        word.lowercased().trimmingCharacters(in: trimSet)
    }
    // Built once: every token of every paragraph on screen goes through normalize.
    private static let trimSet = CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "-'"))

    // Whole-word, case-insensitive: "Ares" matches "Ares," and "ARES" but not "spares".
    // Works for multi-word terms and any script (Character.isLetter covers Greek etc.).
    static func containsWord(_ term: String, in text: String) -> Bool {
        let needle = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return false }
        func isWordChar(_ c: Character?) -> Bool { c.map { $0.isLetter || $0.isNumber } ?? false }
        var from = text.startIndex
        while from < text.endIndex,
              let r = text.range(of: needle, options: .caseInsensitive, range: from..<text.endIndex) {
            let before = r.lowerBound > text.startIndex ? text[text.index(before: r.lowerBound)] : nil
            let after = r.upperBound < text.endIndex ? text[r.upperBound] : nil
            if !isWordChar(before) && !isWordChar(after) { return true }
            from = text.index(after: r.lowerBound)
        }
        return false
    }
}

// Apple's on-device reference dictionary (free, offline, modern) — the tier-2 fallback
// for any word the curated glossary doesn't cover. iOS exposes no API to read the
// definition text inline, so we present the system panel rather than rendering it in
// the WordCard. `hasDefinition` lets us only offer the lookup when the OS actually
// knows the word.
enum SystemDictionary {
    static func hasDefinition(_ term: String) -> Bool {
        UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term)
    }

    static func lookUp(_ term: String) {
        guard let presenter = topViewController() else { return }
        presenter.present(UIReferenceLibraryViewController(term: term), animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
