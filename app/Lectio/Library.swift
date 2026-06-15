import Foundation
import Combine

// Loads the bundled content directory (a folder reference named "content") into
// memory at launch. The bundle is small; loading is synchronous and cheap.
final class Library: ObservableObject {
    @Published var works: [Work] = []
    @Published var editions: [String: Edition] = [:]
    @Published var collections: [BookCollection] = []
    @Published var enrichment: [String: Enrichment] = [:]

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
            }
        }
    }

    func edition(for work: Work) -> Edition? { editions[work.defaultEditionId] }

    func works(in collection: BookCollection) -> [Work] {
        collection.items.compactMap { item in works.first { $0.id == item.workId } }
    }

    func passage(workId: String, sectionId: String) -> Enrichment.Passage? {
        enrichment[workId]?.passages?.first { $0.sectionId == sectionId }
    }

    func chapterOverview(workId: String, order: Int) -> String? {
        enrichment[workId]?.chapters?[String(order)]
    }
}
