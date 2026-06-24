import Foundation
import Combine

// Loads the bundled content directory (a folder reference named "content") into
// memory at launch. The bundle is small; loading is synchronous and cheap.
final class Library: ObservableObject {
    @Published var works: [Work] = []
    @Published var editions: [String: Edition] = [:]
    @Published var collections: [BookCollection] = []
    @Published var enrichment: [String: Enrichment] = [:]
    @Published var explore: [ExploreRecord] = []

    // workId -> normalized term/alias -> curated glossary entry. Built once at load so
    // a tap is an O(1) dictionary hit regardless of which edition's name was tapped.
    private var glossIndex: [String: [String: Enrichment.GlossEntry]] = [:]

    private let decoder = JSONDecoder()

    init() { load() }

    private func url(_ name: String, in sub: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "json", subdirectory: sub)
    }

    private func decode<T: Decodable>(_ type: T.Type, _ name: String, in sub: String) -> T? {
        guard let u = url(name, in: sub),
              let data = try? Data(contentsOf: u) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func load() {
        guard let manifest = decode(Manifest.self, "manifest", in: "content") else { return }

        collections = manifest.collections.compactMap {
            decode(BookCollection.self, $0.id, in: "content/collections")
        }

        for ref in manifest.works {
            let dir = "content/works/\(ref.id)"
            guard let work = decode(Work.self, "work", in: dir) else { continue }
            works.append(work)

            for editionId in work.editionIds {
                let short = String(editionId.split(separator: ".").last ?? "")
                if let edition = decode(Edition.self, short, in: "\(dir)/editions") {
                    editions[editionId] = edition
                }
            }

            if let en = decode(Enrichment.self, "enrichment", in: dir) {
                enrichment[work.id] = en
                if let glossary = en.glossary {
                    var index: [String: Enrichment.GlossEntry] = [:]
                    for entry in glossary {
                        for key in [entry.term] + (entry.aliases ?? []) {
                            index[WordDictionary.normalize(key)] = entry
                        }
                    }
                    glossIndex[work.id] = index
                }
            }
        }

        if let data = decode(ExploreData.self, "explore", in: "content") {
            explore = data.records
        }
    }

    // Build a book-overview route from a title (real work or planned shell) — used by the
    // Explore feed's connection links to jump between related books.
    func bookOverview(title: String) -> BookOverview? {
        if let w = works.first(where: { $0.title == title }) {
            return BookOverview(title: w.title, author: w.author, era: w.composed,
                                overview: w.blurb, workId: w.id, coverPath: nil, tradition: w.tradition)
        }
        for c in collections {
            if let p = (c.planned ?? []).first(where: { $0.title == title }) {
                return BookOverview(title: p.title, author: p.author ?? "", era: p.era ?? "",
                                    overview: p.note ?? "", workId: nil, coverPath: p.cover, tradition: p.tradition)
            }
        }
        return nil
    }

    func edition(for work: Work) -> Edition? { editions[work.defaultEditionId] }

    // A work's cover art, if one is bundled at content/works/<id>/cover.jpg.
    func coverURL(_ workId: String) -> URL? {
        Bundle.main.url(forResource: "cover", withExtension: "jpg",
                        subdirectory: "content/works/\(workId)")
    }

    // A planned work's cover art, if one is bundled under content/.
    func plannedCoverURL(_ coverPath: String?) -> URL? {
        guard let coverPath, !coverPath.isEmpty else { return nil }
        let ns = coverPath as NSString
        let ext = ns.pathExtension.isEmpty ? nil : ns.pathExtension
        let name = ns.deletingPathExtension.components(separatedBy: "/").last ?? ns.deletingPathExtension
        let dir = ns.deletingLastPathComponent
        let subdirectory = dir.isEmpty ? "content" : "content/\(dir)"
        return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
    }

    // A collection's featured introduction image, if bundled at
    // content/collections/<collectionId>-intro.jpg.
    func collectionImageURL(_ collectionId: String) -> URL? {
        Bundle.main.url(forResource: "\(collectionId)-intro", withExtension: "jpg",
                        subdirectory: "content/collections")
    }

    func works(in collection: BookCollection) -> [Work] {
        collection.items.compactMap { item in works.first { $0.id == item.workId } }
    }

    func passage(workId: String, sectionId: String) -> Enrichment.Passage? {
        enrichment[workId]?.passages?.first { $0.sectionId == sectionId }
    }

    // Curated, in-context entry for a tapped word — resolved by term or any alias
    // (Roman names, patronymics, variant spellings). nil if the word isn't curated.
    func glossEntry(workId: String, term: String) -> Enrichment.GlossEntry? {
        glossIndex[workId]?[WordDictionary.normalize(term)]
    }

    func chapterOverview(workId: String, order: Int) -> String? {
        enrichment[workId]?.chapters?[String(order)]
    }
}
