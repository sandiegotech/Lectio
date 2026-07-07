import SwiftUI

// A route to the in-app word study page — Gloss, folded into Lectio. Pushed from the
// WordCard so the deep dive on a word no longer requires leaving the book.
struct WordStudy: Hashable {
    var term: String
    var workId: String
}

// The word's own page: its curated meaning in this book, the idea behind it (the
// concept layer), where it appears across this work's editions, the other books in
// the library that carry it, the system dictionary, and — for the full ecosystem
// experience — the hand-off to the Gloss app as the quiet footer.
struct WordStudyView: View {
    let study: WordStudy
    @EnvironmentObject var library: Library
    @EnvironmentObject var saved: SavedStore
    @Environment(\.colorScheme) private var colorScheme
    private var pal: Palette { Palette.forScheme(colorScheme) }

    private var work: Work? { library.works.first { $0.id == study.workId } }
    private var entry: Enrichment.GlossEntry? {
        library.glossEntry(workId: study.workId, term: study.term)
    }
    private var concept: Concept? {
        entry?.conceptId.flatMap { library.concept(id: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let gloss = entry?.gloss {
                    section("In this book") {
                        Text(gloss)
                            .font(.system(size: 17, design: .serif)).lineSpacing(5)
                            .foregroundColor(pal.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    section("In this book") {
                        Text("This word isn't in the curated glossary — the dictionary below covers it.")
                            .font(.footnote).foregroundColor(pal.inkSoft)
                    }
                }

                if let aliases = entry?.aliases, !aliases.isEmpty {
                    section("Also appears as") {
                        Text(aliases.joined(separator: "  ·  "))
                            .font(.system(.subheadline, design: .serif)).italic()
                            .foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let c = concept {
                    section("The idea behind it") { conceptCard(c) }
                }

                if !occurrences.isEmpty {
                    section("In the text") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(occurrences, id: \.editionId) { occ in
                                HStack(spacing: 6) {
                                    Text(occ.label).font(.footnote.weight(.medium)).foregroundColor(pal.ink)
                                    Text("\(occ.count) \(occ.count == 1 ? "passage" : "passages")\(occ.firstIn.map { " · first in \($0)" } ?? "")")
                                        .font(.footnote).foregroundColor(pal.inkSoft)
                                    Spacer(minLength: 0)
                                }
                            }
                            NavigationLink(value: ReaderRoute(workId: study.workId, target: .word(study.term))) {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.magnifyingglass").font(.caption)
                                    Text("Read in context").font(.caption.weight(.semibold))
                                    Image(systemName: "chevron.right").font(.system(size: 8, weight: .semibold))
                                }
                                .foregroundColor(pal.accent)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                }

                if !elsewhere.isEmpty {
                    section("Across the library") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(elsewhere, id: \.workId) { row in
                                NavigationLink(value: ReaderRoute(workId: row.workId, target: .word(row.term))) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(row.title)
                                                .font(.system(.headline, design: .serif)).foregroundColor(pal.ink)
                                            Spacer(minLength: 0)
                                            Image(systemName: "chevron.right")
                                                .font(.caption2.weight(.semibold)).foregroundColor(pal.accent)
                                        }
                                        Text(row.gloss).font(.footnote).foregroundColor(pal.inkSoft)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(pal.rail))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(pal.rule))
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                actionsFooter
            }
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
        }
        .background(pal.paper.ignoresSafeArea())
        .navigationTitle(study.term.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(study.term.capitalized)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundColor(pal.ink)
                if let kind = entry?.kind, !kind.isEmpty {
                    Text(kind.uppercased())
                        .font(.system(size: 10, weight: .semibold)).tracking(0.8)
                        .foregroundColor(pal.inkSoft)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().stroke(pal.rule))
                }
                Spacer(minLength: 0)
                saveButton
            }
            if let w = work {
                Text("Studied from \(w.title)")
                    .font(.caption).foregroundColor(pal.inkSoft)
            }
            Rectangle().fill(pal.rule).frame(height: 1).padding(.top, 6)
        }
    }

    private var saveButton: some View {
        Button {
            saved.toggle(SavedWord(term: study.term, definition: entry?.gloss ?? "",
                                   workTitle: work?.title, workId: study.workId))
        } label: {
            Image(systemName: saved.isSaved(study.term) ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundColor(saved.isSaved(study.term) ? pal.gold : pal.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private func conceptCard(_ c: Concept) -> some View {
        NavigationLink(value: c) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(c.term.capitalized)
                        .font(.system(.headline, design: .serif)).foregroundColor(pal.ink)
                    if let o = c.original {
                        Text(o.lemma).font(.system(.subheadline, design: .serif)).foregroundColor(pal.inkSoft)
                        if let t = o.translit {
                            Text(t).font(.caption.italic()).foregroundColor(pal.inkSoft)
                        }
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        Text("Trace this idea").font(.caption.weight(.semibold))
                        Image(systemName: "chevron.right").font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundColor(pal.accent)
                }
                if let sense = c.senseHistory {
                    Text(sense).font(.footnote).foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(pal.rail))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(pal.rule))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: dictionary + Gloss footer

    private var actionsFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle().fill(pal.rule).frame(height: 1)
            HStack(spacing: 10) {
                if SystemDictionary.hasDefinition(study.term) {
                    Button { SystemDictionary.lookUp(study.term) } label: {
                        Label("Dictionary", systemImage: "character.book.closed")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .foregroundColor(pal.accent)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(pal.rule))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    if glossInstalled { GlossLink.open(term: study.term, sourceTitle: work?.title) }
                    else { GlossLink.openWebsite() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle.magnifyingglass").font(.caption2)
                        Text(glossInstalled ? "Open in Gloss" : "Go deeper with Gloss")
                            .font(.caption.weight(.medium))
                        Image(systemName: "arrow.up.forward").font(.system(size: 9, weight: .semibold))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .foregroundColor(pal.accent)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(pal.rule))
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
        }
    }

    private var glossInstalled: Bool {
        guard let u = URL(string: "gloss://define") else { return false }
        return UIApplication.shared.canOpenURL(u)
    }

    // MARK: occurrences — where the word appears, per edition of this work

    private struct EditionOccurrence {
        var editionId: String
        var label: String
        var count: Int
        var firstIn: String?
    }

    private var occurrences: [EditionOccurrence] {
        guard let w = work else { return [] }
        let needles = ([study.term] + (entry?.aliases ?? [])).map { $0.lowercased() }
        return w.editionIds.compactMap { eid -> EditionOccurrence? in
            guard let ed = library.edition(eid), !ed.sections.isEmpty else { return nil }
            var count = 0
            var firstIn: String?
            for sec in ed.sections {
                for seg in sec.segments {
                    let t = seg.text.lowercased()
                    if needles.contains(where: { t.contains($0) }) {
                        count += 1
                        if firstIn == nil { firstIn = sec.label }
                    }
                }
            }
            guard count > 0 else { return nil }
            return EditionOccurrence(editionId: eid, label: editionShortLabel(ed),
                                     count: count, firstIn: firstIn)
        }
    }

    private func editionShortLabel(_ ed: Edition) -> String {
        switch ed.kind {
        case "modern": return "Lectio Edition"
        case "original": return "Original"
        default: return ed.translator ?? "Translation"
        }
    }

    // MARK: across the library — other works whose glossary carries this word

    private struct LibraryRow {
        var workId: String
        var title: String
        var term: String
        var gloss: String
    }

    private var elsewhere: [LibraryRow] {
        library.works.compactMap { w -> LibraryRow? in
            guard w.id != study.workId,
                  let e = library.glossEntry(workId: w.id, term: study.term) else { return nil }
            return LibraryRow(workId: w.id, title: w.title, term: e.term, gloss: e.gloss)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold)).tracking(2).foregroundColor(pal.accent)
            content()
        }
    }
}
