import Foundation
import Combine

// Loads the bundled content directory (a folder reference named "content") into
// memory at launch. Work metadata is small and loads synchronously; edition texts
// decode lazily on first open.
final class Library: ObservableObject {
    // The readable shelf: every work whose release date has arrived.
    @Published private(set) var works: [Work] = []
    @Published var enrichment: [String: Enrichment] = [:]
    @Published var explore: [ExploreRecord] = []
    @Published var concepts: [String: Concept] = [:]   // concept.id -> node
    // Series collections (Lectio, Harvard Classics, …), in manifest order — the Library's
    // "Collection" sort groups readable works under these.
    private(set) var collections: [BookCollection] = []

    // Every work in the bundle, released or not; `works` is filtered from this.
    private var allWorks: [Work] = []

    // workId -> normalized term/alias -> curated glossary entry. Built once at load so
    // a tap is an O(1) dictionary hit regardless of which edition's name was tapped.
    private var glossIndex: [String: [String: Enrichment.GlossEntry]] = [:]

    // Editions decode lazily — the full texts are ~20 MB of JSON, far too much to parse
    // before the shelf appears. Launch records where each edition lives; the first open
    // of a book pays its own (small) decode and the cache keeps it. Guarded by a lock
    // because word study scans editions off the main thread.
    private var editionDir: [String: String] = [:]     // editionId -> "content/works/<id>"
    private var editionCache: [String: Edition] = [:]
    private var infoCache: [String: EditionInfo] = [:]
    private var omitted: [String: String] = [:]   // omitted segment id -> next readable id
    private let lock = NSLock()

    // The edition as the app sees it: segments of kind "omit" (an editor's note or an
    // invented line, kept in the bundle only because segment ids are frozen) are removed
    // here, once, so the reader, Compare, progress, search, word study, Explore, the
    // Docent and cross-edition matching never meet them.
    func edition(_ id: String) -> Edition? {
        lock.lock(); defer { lock.unlock() }
        if let e = editionCache[id] { return e }
        guard let dir = editionDir[id] else { return nil }
        guard var e = decode(Edition.self, editionFile(id), in: "\(dir)/editions") else { return nil }
        var pending: [String] = []
        for si in e.sections.indices {
            var kept: [Segment] = []
            for seg in e.sections[si].segments {
                if seg.kind == "omit" { pending.append(seg.id); continue }
                for o in pending { omitted[o] = seg.id }
                pending.removeAll()
                kept.append(seg)
            }
            e.sections[si].segments = kept
        }
        if let last = e.sections.last?.segments.last?.id { for o in pending { omitted[o] = last } }
        editionCache[id] = e
        return e
    }

    // A saved place may point at a segment that is now omitted: land on the next real one.
    func readableAnchor(_ id: String) -> String {
        lock.lock(); defer { lock.unlock() }
        return omitted[id] ?? id
    }

    // An edition's name fields, without decoding its text when it isn't open yet.
    func editionInfo(_ id: String) -> EditionInfo? {
        lock.lock(); defer { lock.unlock() }
        if let e = editionCache[id] { return e.info }
        if let i = infoCache[id] { return i }
        guard let dir = editionDir[id],
              let i = decode(EditionInfo.self, editionFile(id), in: "\(dir)/editions") else { return nil }
        infoCache[id] = i
        return i
    }

    // A work's editions in reading order (Lectio first, the original last).
    func editionInfos(for work: Work) -> [EditionInfo] {
        work.editionIds.compactMap { editionInfo($0) }.sorted(by: EditionInfo.readingOrder)
    }

    private func editionFile(_ id: String) -> String { String(id.split(separator: ".").last ?? "") }

    private let decoder = JSONDecoder()

    init() {
        load()
        // A book appears on its release date without a relaunch: re-check at midnight
        // while the app is open (LectioApp also re-checks on returning to the foreground).
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil,
                                               queue: .main) { [weak self] _ in
            self?.refreshReleases()
        }
    }

    private func url(_ name: String, in sub: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "json", subdirectory: sub)
    }

    private func decode<T: Decodable>(_ type: T.Type, _ name: String, in sub: String) -> T? {
        guard let u = url(name, in: sub),
              let data = try? Data(contentsOf: u) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func load() {
        #if DEBUG
        let t0 = Date()
        defer { print("LECTIO library load: \(Int(Date().timeIntervalSince(t0) * 1000))ms") }
        #endif
        guard let manifest = decode(Manifest.self, "manifest", in: "content") else { return }
        collections = manifest.collections
            .compactMap { decode(BookCollection.self, $0.id, in: "content/collections") }
            .filter { $0.kind == "series" }

        for ref in manifest.works {
            let dir = "content/works/\(ref.id)"
            guard let work = decode(Work.self, "work", in: dir) else { continue }
            allWorks.append(work)

            for editionId in work.editionIds {
                editionDir[editionId] = dir
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
        refreshReleases()

        if let data = decode(ExploreData.self, "explore", in: "content") {
            explore = data.records
        }

        if let graph = decode(GraphData.self, "concepts", in: "content/graph") {
            concepts = Dictionary(graph.concepts.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        }
    }

    // MARK: release dates

    // Recompute the readable shelf for today. Publishes only when it changes.
    func refreshReleases() {
        let released = allWorks.filter { Self.isReleased($0.releaseDate) }
        if released.map(\.id) != works.map(\.id) { works = released }
    }

    // "YYYY-MM-DD" on or before today in the device's calendar. Absent means released;
    // a malformed date keeps the work hidden rather than leaking it early.
    private static func isReleased(_ date: String?) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["LECTIO_DEBUG_ALL_RELEASES"] != nil { return true }
        #endif
        guard let date else { return true }
        let parts = date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else {
            #if DEBUG
            print("LECTIO malformed releaseDate: \(date)")
            #endif
            return false
        }
        let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let t = [today.year ?? 0, today.month ?? 0, today.day ?? 0]
        return parts.lexicographicallyPrecedes(t) || parts == t
    }

    // MARK: lookups

    func work(id: String) -> Work? { works.first { $0.id == id } }

    // The overview route for a readable work with this title; nil for anything else,
    // so links to unreleased or unknown titles render as plain text.
    func bookOverview(title: String) -> BookOverview? {
        works.first { $0.title == title }.map(BookOverview.init)
    }

    // A work's cover art, if one is bundled at content/works/<id>/cover.jpg.
    func coverURL(_ workId: String) -> URL? {
        Bundle.main.url(forResource: "cover", withExtension: "jpg",
                        subdirectory: "content/works/\(workId)")
    }

    // Passage enrichment is authored against one edition's section IDs (e.g.
    // edition.iliad.butler-1898.book-01), but the reader is usually in another edition
    // (lectio-modern by default). Sections share their slug across editions, so fall
    // back to matching the trailing slug — the same passage surfaces in every edition.
    func passage(workId: String, sectionId: String) -> Enrichment.Passage? {
        guard let passages = enrichment[workId]?.passages else { return nil }
        if let exact = passages.first(where: { $0.sectionId == sectionId }) { return exact }
        guard let slug = sectionId.split(separator: ".").last else { return nil }
        return passages.first { $0.sectionId.hasSuffix("." + slug) }
    }

    // Curated, in-context entry for a tapped word — resolved by term or any alias
    // (Roman names, patronymics, variant spellings). nil if the word isn't curated.
    func glossEntry(workId: String, term: String) -> Enrichment.GlossEntry? {
        glossIndex[workId]?[WordDictionary.normalize(term)]
    }

    // The work's concept-bearing terms (glossary entries bound to a Concept node, plus
    // their aliases) — the "important words" the reader gets a whisper of an underline for.
    private var conceptTermCache: [String: Set<String>] = [:]
    func conceptTerms(workId: String) -> Set<String> {
        if let cached = conceptTermCache[workId] { return cached }
        var out = Set<String>()
        for g in enrichment[workId]?.glossary ?? [] where g.conceptId != nil {
            out.insert(WordDictionary.normalize(g.term))
            for a in g.aliases ?? [] { out.insert(WordDictionary.normalize(a)) }
        }
        conceptTermCache[workId] = out
        return out
    }

    func concept(id: String) -> Concept? { concepts[id] }

    // Every concept node, alphabetical — the Ideas doorway's source.
    var allConcepts: [Concept] { concepts.values.sorted { $0.term.lowercased() < $1.term.lowercased() } }

    // The glossary entry a work binds to a concept (its work-local gloss + local term).
    func glossEntry(workId: String, conceptId: String) -> Enrichment.GlossEntry? {
        enrichment[workId]?.glossary?.first { $0.conceptId == conceptId }
    }

    func workTitle(id: String) -> String? { work(id: id)?.title }

    func chapterOverview(workId: String, order: Int) -> String? {
        enrichment[workId]?.chapters?[String(order)]
    }
}

extension Work {
    // Rough sortable year from the composed string ("c. 800–200 BCE", "1513", "8th–9th c."…),
    // so the library reads earliest to latest.
    var sortYear: Int {
        let s = composed.lowercased()
        if s.hasPrefix("ancient") { return -2000 }
        guard let start = s.firstIndex(where: { $0.isNumber }) else { return 3000 }
        var j = start, n = 0
        while j < s.endIndex, let d = s[j].wholeNumberValue { n = n * 10 + d; j = s.index(after: j) }
        let after = s[j...]
        let century = after.hasPrefix("st") || after.hasPrefix("nd")
                   || after.hasPrefix("rd") || after.hasPrefix("th")
        let bce = s.contains("bce") || s.contains(" bc")
        if century { return bce ? -(n * 100) : (n - 1) * 100 }
        return bce ? -n : n
    }
}

// Off the main thread, only `edition(_:)` and `editionInfo(_:)` are called, and both hold
// the lock; everything else is touched on the main thread.
extension Library: @unchecked Sendable {}
