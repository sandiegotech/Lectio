import SwiftUI

// Explore: one famous line at a time, a page each, with the book it comes from and one
// way in — "Read this passage" opens the book at that line. Only books in the library;
// the order is shuffled once a day and holds all day. A row of ideas at the top narrows
// the lines to the books an idea runs through.
struct ExploreFeed: View {
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var idea: Concept?
    @State private var current: String?
    private var pal: Palette { Palette.forScheme(colorScheme) }

    var body: some View {
        let shown = lines
        VStack(spacing: 6) {
            ideaRow
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(shown, id: \.record.id) { line in
                        ExploreCard(record: line.record, work: line.work)
                            .containerRelativeFrame(.vertical)
                            .scrollTransition(.interactive, axis: .vertical) { view, phase in
                                view.opacity(phase.isIdentity ? 1 : 0.35)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.94)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $current)
            .overlay(alignment: .trailing) { pageDots(shown.map(\.record.id)) }
            .id(idea?.id ?? "all")   // a new idea starts at its first line
        }
    }

    // A quiet position indicator down the right edge.
    private func pageDots(_ ids: [String]) -> some View {
        let at = ids.firstIndex(of: current ?? "") ?? 0
        return VStack(spacing: 5) {
            ForEach(ids.indices, id: \.self) { i in
                Circle().fill(i == at ? pal.accent : pal.inkSoft.opacity(0.3))
                    .frame(width: i == at ? 6 : 4, height: i == at ? 6 : 4)
            }
        }
        .padding(.trailing, hSize == .regular ? 14 : 5)
        .allowsHitTesting(false)
        .accessibilityLabel("Line \(at + 1) of \(ids.count)")
    }

    private var readable: [(record: ExploreRecord, work: Work)] {
        library.explore.compactMap { r in library.works.first { $0.title == r.title }.map { (r, $0) } }
    }

    private var lines: [(record: ExploreRecord, work: Work)] {
        let seed = daySeed()
        let all = readable.sorted { dayHash($0.record.title, seed) < dayHash($1.record.title, seed) }
        guard let idea else { return all }
        let ids = Set(idea.appearsIn ?? [])
        return all.filter { ids.contains($0.work.id) }
    }

    // Ideas worth filtering by: those that run through at least two of the lines' books,
    // the widest-reaching first.
    private var ideas: [Concept] {
        let ids = Set(readable.map(\.work.id))
        func reach(_ c: Concept) -> Int { Set(c.appearsIn ?? []).intersection(ids).count }
        return library.allConcepts.filter { reach($0) >= 2 }
            .sorted { reach($0) != reach($1) ? reach($0) > reach($1) : $0.term < $1.term }
    }

    @ViewBuilder
    private var ideaRow: some View {
        if !ideas.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ideas) { c in
                        let on = idea?.id == c.id
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { idea = on ? nil : c }
                        } label: {
                            Text(c.term.capitalized)
                                .font(.system(.subheadline, design: .serif))
                                .foregroundColor(on ? .white : pal.ink)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(on ? pal.accent : pal.rail))
                                .overlay(Capsule().stroke(on ? Color.clear : pal.rule))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, hSize == .regular ? 26 : 20)
            }
        }
    }

    // One stable order per day: seeded by the local date, so it holds all day and turns
    // over the next.
    private func daySeed() -> Int {
        let midnight = Calendar.current.startOfDay(for: Date())
        return Int(midnight.timeIntervalSince1970 / 86_400)
    }
    private func dayHash(_ s: String, _ seed: Int) -> UInt64 {   // FNV-1a (Hasher isn't stable across launches)
        var h: UInt64 = 14695981039346656037
        for b in "\(seed):\(s)".utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return h
    }
}

// One line as a page of its own: a red opening mark, the line set large, a short rule,
// the author in small caps and the title in italic, the book itself, and "Read this
// passage". The sheet takes its tone from the book's boards — pale parchment for the
// Western covers, deep navy for the Eastern — so the sequence has colour and rhythm.
private struct ExploreCard: View {
    let record: ExploreRecord
    let work: Work
    @EnvironmentObject var library: Library
    @EnvironmentObject var opener: BookOpener
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var cover = CoverFrame()
    @State private var passage: (edition: String, segment: String)?
    private var pal: Palette { Palette.forScheme(colorScheme) }
    private var wide: Bool { hSize == .regular }

    private struct Sheet { var fill: Color; var ink: Color; var soft: Color; var red: Color; var edge: Color }

    // The sheet's colours, from the cover's average tone.
    private var sheet: Sheet {
        let tone = CoverCache.tone(at: library.coverURL(work.id))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        tone?.getRed(&r, green: &g, blue: &b, alpha: &a)
        let dark = tone != nil && (0.299 * r + 0.587 * g + 0.114 * b) < 0.4
        if dark {
            let cream = Color(hex: 0xEFE6D2)
            return Sheet(fill: Color(uiColor: tone!), ink: cream, soft: Color(hex: 0xC6A867),
                         red: Palette.dark.accent, edge: Color(hex: 0xC6A867).opacity(0.35))
        }
        // Pale boards: the cover's tone washed halfway toward the page (day only).
        let fill = (tone != nil && colorScheme != .dark)
            ? Color(red: r * 0.45 + 0.955 * 0.55, green: g * 0.45 + 0.933 * 0.55, blue: b * 0.45 + 0.882 * 0.55)
            : pal.rail
        return Sheet(fill: fill, ink: pal.ink, soft: pal.inkSoft, red: pal.accent, edge: pal.rule)
    }

    var body: some View {
        let sh = sheet
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            Text("\u{201C}")
                .font(.system(size: wide ? 96 : 76, weight: .regular, design: .serif))
                .foregroundColor(sh.red)
                .frame(height: wide ? 58 : 46, alignment: .top)
            Text(record.quote)
                .font(.system(size: wide ? 34 : 26, design: .serif))
                .lineSpacing(wide ? 12 : 8)
                .multilineTextAlignment(.center)
                .foregroundColor(sh.ink)
                .frame(maxWidth: wide ? 520 : 310)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.8)
            Rectangle().fill(sh.soft.opacity(0.6)).frame(width: 36, height: 1)
                .padding(.top, wide ? 30 : 24).padding(.bottom, 14)
            if !work.author.isEmpty {
                Text(work.author.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .serif)).tracking(2.4)
                    .foregroundColor(sh.soft)
                    .multilineTextAlignment(.center)
            }
            Text(work.title)
                .font(.system(.body, design: .serif)).italic()
                .foregroundColor(sh.ink)
                .padding(.top, 4)
            // The line is in a translator's words, not Lectio's: say whose.
            if let credit = passage.flatMap({ library.editionInfo($0.edition)?.credit }) {
                Text(credit.uppercased())
                    .font(.system(size: 9.5, weight: .medium, design: .serif)).tracking(1.6)
                    .foregroundColor(sh.soft.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            Spacer(minLength: 16)
            BookCoverArt(work: work)
                .frame(width: wide ? 130 : 96)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cover.frame = $0 }
                .opacity(opener.opening?.work.id == work.id ? 0 : 1)
            Button {
                let route = passage.map {
                    OpenRoute.reader(ReaderRoute(workId: work.id, target: .passage($0.segment)))
                }
                opener.open(work, from: cover.frame, to: route)
            } label: {
                Text("Read this passage")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 26).padding(.vertical, 12)
                    .background(Capsule().fill(sh.red))
            }
            .buttonStyle(.plain)
            .padding(.top, 22)
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: wide ? 640 : .infinity, maxHeight: wide ? 900 : .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(sh.fill))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(sh.edge, lineWidth: 1))
        .shadow(color: .black.opacity(0.14), radius: 16, y: 8)
        .padding(.horizontal, wide ? 40 : 18)
        .padding(.vertical, wide ? 28 : 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { passage = await ExplorePassage.find(record.quote, in: work, library: library) }
    }
}

// Where a famous line sits in the text: the first segment, in any edition of the work,
// that contains the line's opening words. Searched once per line, off the main thread.
enum ExplorePassage {
    private static var cache: [String: (String, String)] = [:]
    private static let lock = NSLock()

    static func find(_ quote: String, in work: Work, library: Library) async -> (edition: String, segment: String)? {
        if let hit = lock.withLock({ cache[quote] }) { return hit }
        let needle = String(squash(quote).prefix(36))
        guard needle.count >= 12 else { return nil }
        let ids = library.editionInfos(for: work).map(\.id)
        return await withCheckedContinuation { done in
            DispatchQueue.global(qos: .utility).async {
                for eid in ids {
                    guard let ed = library.edition(eid) else { continue }
                    for sec in ed.sections {
                        for seg in sec.segments where squash(seg.text).contains(needle) {
                            lock.lock(); cache[quote] = (eid, seg.id); lock.unlock()
                            done.resume(returning: (eid, seg.id))
                            return
                        }
                    }
                }
                done.resume(returning: nil)
            }
        }
    }

    // Letters and digits only, lowercased, single spaces — punctuation and line breaks differ.
    private static func squash(_ s: String) -> String {
        s.lowercased().unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? String($0) : " " }
            .joined()
            .split(separator: " ").joined(separator: " ")
    }
}
