import SwiftUI
import UIKit

// Opens the word in the sibling SDIT app, Gloss — trying its URL scheme first and
// falling back to the web. The personal vocabulary layer is shared across SDIT apps
// (BIBLE §8): a word looked up here is there to study in Gloss. (In-app word study
// lives in WordStudyView; this is the ecosystem hand-off, offered as a quiet footer.)
enum GlossLink {
    // Hands the word to Gloss *with the passage it sits in* (`context`) and the book
    // it came from (`sourceTitle`), so Gloss can explain the word as it's used here —
    // Homer's "wrath," not the dictionary's. Long segments are trimmed to keep the URL
    // sane; Gloss only needs enough surrounding text to disambiguate.
    static func open(term: String, context: String? = nil, sourceTitle: String? = nil) {
        var comps = URLComponents()
        comps.scheme = "gloss"
        comps.host = "define"
        var items = [URLQueryItem(name: "term", value: term)]
        if let context = context?.trimmingCharacters(in: .whitespacesAndNewlines), !context.isEmpty {
            items.append(URLQueryItem(name: "context", value: String(context.prefix(1000))))
        }
        if let sourceTitle, !sourceTitle.isEmpty {
            items.append(URLQueryItem(name: "title", value: sourceTitle))
        }
        comps.queryItems = items
        guard let scheme = comps.url else { return }

        let q = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let web = URL(string: "https://sandiegotech.org/gloss?q=\(q)")
        UIApplication.shared.open(scheme, options: [:]) { opened in
            if !opened, let web { UIApplication.shared.open(web) }
        }
    }

    // When Gloss isn't installed: open its page so the reader can discover/get it.
    static func openWebsite() {
        if let url = URL(string: "https://sandiegotech.org/gloss") {
            UIApplication.shared.open(url)
        }
    }
}
