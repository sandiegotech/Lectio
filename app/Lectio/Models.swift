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
    var collections: [String]
    var editionIds: [String]
}

struct CollectionItem: Codable, Hashable {
    var workId: String
    var volume: Int?
    var note: String?
}

struct BookCollection: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var curator: String
    var blurb: String
    var items: [CollectionItem]
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
    var passages: [Passage]
}

// Just enough of manifest.json to enumerate what to load.
struct Manifest: Codable {
    struct CollRef: Codable { var id: String; var title: String }
    struct WorkRef: Codable { var id: String }
    var collections: [CollRef]
    var works: [WorkRef]
}
