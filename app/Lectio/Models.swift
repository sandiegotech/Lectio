import Foundation

// Codable mirror of the content bundle (CONTENT_PIPELINE.md §2, §7).
// Field names match the published JSON exactly. None-valued fields are dropped
// by the pipeline, so the optionals below absorb anything not present.

struct Provenance: Codable, Hashable {
    var source: String
    var rightsStatus: String
    var rightsNote: String?
    var sourceUrl: String?
    var sourceId: String?
    var retrievedDate: String?
    var aiModel: String?
    var aiSourceEditionId: String?
    var aiProfile: String?
    var sourcesCited: [String]?
    var tokensEstimated: Int?
    var vintage: Int?
    var creator: String?
    var holdingInstitution: String?
}

struct SpineRange: Codable, Hashable {
    var from: String
    var to: String
}

struct Segment: Codable, Hashable, Identifiable {
    var id: String
    var order: Int
    var kind: String
    var text: String
    var spine: SpineRange?
}

struct Section: Codable, Hashable, Identifiable {
    var id: String
    var order: Int
    var label: String
    var title: String?
    var segments: [Segment]
}

struct Edition: Codable, Hashable, Identifiable {
    // A notable place where the Lectio Edition departs from older translations, with the reason.
    struct Divergence: Codable, Hashable {
        var locus: String?      // "Book 1, line 1"
        var phrase: String?     // the original-language word/phrase at issue
        var older: String       // how earlier translations render it
        var lectio: String      // how the Lectio Edition renders it
        var note: String        // why — the scholarly reasoning
    }
    var id: String
    var workId: String
    var kind: String
    var language: String
    var form: String
    var provenance: Provenance
    var translator: String?
    var translatorYears: String?
    var publishedYear: Int?
    var character: String
    var overview: String?       // fuller note: the translator's approach + how it compares to others
    var introduction: String?
    var divergences: [Divergence]?
    var sections: [Section]
}

struct Work: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var author: String
    var originalLang: String
    var composed: String
    var type: String
    var referenceScheme: String
    var defaultEditionId: String
    var blurb: String
    var tradition: String?        // "West" | "East"
    var collections: [String]
    var editionIds: [String]
}

struct CollectionItem: Codable, Hashable {
    var workId: String
    var volume: Int?
    var note: String?
    var part: String?   // sub-section within the collection (e.g. "The New Testament")
}

struct BookCollection: Codable, Hashable, Identifiable {
    // A shell on the shelf — a planned work not yet ingested.
    struct Planned: Codable, Hashable {
        var title: String
        var author: String?
        var era: String?       // when the work is from (e.g. "c. 800–200 BCE")
        var part: String?      // sub-section within the collection (e.g. "India")
        var note: String?      // a basic one-line overview
        var tradition: String? // "West" | "East"
        var cover: String?     // optional path under content/ for a planned-work cover
        var originalCover: String? // optional cover for the public-domain/source translation
        var rights: String?    // "in-copyright" when not yet free to read
        var opens: Int?        // year it enters the public domain

        var isLocked: Bool { rights == "in-copyright" }
    }
    var id: String
    var title: String
    var curator: String
    var blurb: String
    var about: String?         // backstory shown on the collection's own page
    var introduction: String?  // a longer readable Lectio overview (the "introduction")
    var kind: String?          // "series" | "theme" (defaults to series when absent)
    var group: String?         // optional umbrella header (e.g. "Religious Texts")
    var items: [CollectionItem]
    var planned: [Planned]?

    var isGenre: Bool { kind == "genre" }

    // Total readable works on the shelf (ingested works + planned shells).
    var workCount: Int { items.count + (planned?.count ?? 0) }
}

// Editorial enrichment sidecar that powers the margin rail. Hand-authored seed
// today; the shape the connection graph (BIBLE.md §4.3) will later populate.
struct Enrichment: Codable {
    struct Define: Codable, Hashable {
        var term: String
        var gloss: String
        var source: String?
    }
    struct Connection: Codable, Hashable {
        var label: String
        var kind: String   // author | idea | work | place
    }
    struct Passage: Codable {
        var sectionId: String
        var people: [String]?
        var define: [Define]?
        var connections: [Connection]?
    }
    var workId: String
    var source: String?
    var passages: [Passage]?
    var chapters: [String: String]?   // book number (string) -> overview

    // Work-level annotation dictionary (BIBLE §8.1): curated, in-context entries a
    // modern reader will stumble on (people, gods, places, concepts). `aliases` let a
    // tap resolve across editions — Butler/Pope use Roman names ("Jove") and
    // patronymics ("Pelides"); lectio-modern uses the Greek. Tap-to-define resolves
    // against this first, then falls through to the on-device model (the Docent),
    // then to Apple's dictionary.
    struct GlossEntry: Codable, Hashable {
        var term: String
        var gloss: String
        var kind: String?            // person | god | place | people | concept | thing
        var aliases: [String]?
        var conceptId: String?       // links to a shared Concept node (content/graph/concepts.json)
    }
    var glossary: [GlossEntry]?
}

// The shared cross-work concept layer (content/graph/concepts.json, CONTENT_PIPELINE §7
// "/graph"). A Concept is work-agnostic: the in-context gloss and cross-edition aliases
// live in each work's enrichment glossary, while the Concept holds the universal data —
// original-language lemma, how the word traveled into English, which works it appears in,
// and edges to other concepts/works. This is the backbone the glossary, Explore, and the
// alignment spine all resolve against.
struct GraphData: Codable { var concepts: [Concept] }

struct Concept: Codable, Hashable, Identifiable {
    struct Original: Codable, Hashable {
        var lang: String        // grc | lat | ...
        var lemma: String       // μῆνις
        var translit: String?   // mēnis
        var literal: String?    // "wrath, rage"
    }
    struct Edge: Codable, Hashable {
        var to: String          // "concept.kleos" | "work.homer.odyssey"
        var type: String        // influences | contrasts | shares-theme | parallel | part-of
        var note: String?
    }
    var id: String              // concept.menis
    var term: String
    var kind: String?
    var gloss: String           // cross-work default explanation
    var original: Original?
    var senseHistory: String?
    var appearsIn: [String]?    // workIds
    var connections: [Edge]?
}

// Just enough of manifest.json to enumerate what to load.
struct Manifest: Codable {
    struct CollRef: Codable { var id: String; var title: String }
    struct WorkRef: Codable { var id: String }
    var collections: [CollRef]
    var works: [WorkRef]
}

// The Explore / "famous lines" layer (content/explore.json) — a discovery nugget per book:
// a signature quote, its essence, themes, and cross-tradition connections to other works.
struct ExploreData: Codable { var records: [ExploreRecord] }

struct ExploreRecord: Codable, Hashable, Identifiable {
    struct Link: Codable, Hashable {
        var to: String      // target work title
        var type: String    // influences | responds-to | shares-theme | parallel | contrasts
        var note: String
    }
    var title: String
    var author: String
    var quote: String
    var source: String
    var essence: String
    var themes: [String]
    var connections: [Link]
    var original: String?         // the original-language source text + where the PD version lives
    var translationNote: String?  // an interesting note on how the work has been translated
    var id: String { title }
}
