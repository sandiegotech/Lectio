import SwiftUI

// A concept's own page — the cross-work idea layer made browsable. One idea (rage,
// virtue, the Way), its original word and how it traveled into English, the threads
// to related ideas, and every book in the library where it lives — each with that
// book's own gloss and a jump straight into the text where the idea appears.
struct ConceptDetailView: View {
    let concept: Concept
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var colorScheme
    private var pal: Palette { Palette.forScheme(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                Text(concept.gloss)
                    .font(.system(size: 17, design: .serif)).lineSpacing(5)
                    .foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let sense = concept.senseHistory, !sense.isEmpty {
                    sectionLabel("How the word traveled")
                    Text(sense)
                        .font(.system(size: 15, design: .serif)).italic().lineSpacing(4)
                        .foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !threads.isEmpty {
                    sectionLabel("Threads")
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(threads, id: \.self) { edgeRow($0) }
                    }
                }

                if !livesIn.isEmpty {
                    sectionLabel("Where it lives")
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(livesIn, id: \.workId) { workRow($0) }
                    }
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
        }
        .background(pal.paper.ignoresSafeArea())
        .navigationTitle(concept.term.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text((concept.kind ?? "an idea").uppercased())
                .font(.caption2.weight(.semibold)).tracking(2).foregroundColor(pal.accent)
            Text(concept.term.capitalized)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundColor(pal.ink)
            if let o = concept.original {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(o.lemma)
                        .font(.system(size: 20, design: .serif)).foregroundColor(pal.ink)
                    if let t = o.translit {
                        Text(t).font(.subheadline.italic()).foregroundColor(pal.inkSoft)
                    }
                    if let lit = o.literal {
                        Text("“\(lit)”").font(.subheadline).foregroundColor(pal.inkSoft)
                    }
                    Text(languageName(o.lang))
                        .font(.caption2).foregroundColor(pal.inkSoft)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().stroke(pal.rule))
                }
            }
            Rectangle().fill(pal.rule).frame(height: 1).padding(.top, 6)
        }
    }

    // MARK: threads — edges to other concepts and works

    // Only edges that lead somewhere: a known concept, or a work in the library.
    private var threads: [Concept.Edge] {
        (concept.connections ?? []).filter { e in
            e.to.hasPrefix("concept.") ? library.concept(id: e.to) != nil : library.work(id: e.to) != nil
        }
    }

    @ViewBuilder
    private func edgeRow(_ e: Concept.Edge) -> some View {
        let row = HStack(alignment: .top, spacing: 8) {
            Image(systemName: edgeIcon(e.type)).font(.caption)
                .foregroundColor(pal.accent).padding(.top, 2).frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(edgeTitle(e))
                    .font(.subheadline.weight(.medium)).foregroundColor(pal.accent)
                if let note = e.note {
                    Text(note).font(.caption).foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        if let c = library.concept(id: e.to) {
            NavigationLink(value: c) { row }.buttonStyle(.plain)
        } else if let w = library.work(id: e.to) {
            NavigationLink(value: BookOverview(w)) { row }.buttonStyle(.plain)
        }
    }

    private func edgeTitle(_ e: Concept.Edge) -> String {
        library.concept(id: e.to)?.term.capitalized ?? library.workTitle(id: e.to) ?? e.to
    }

    private func edgeIcon(_ type: String) -> String {
        switch type {
        case "influences": return "arrow.right"
        case "contrasts": return "arrow.left.and.right"
        case "parallel": return "equal"
        case "part-of": return "square.stack"
        default: return "link"
        }
    }

    // MARK: where it lives — each library work carrying this idea

    private struct Occurrence {
        var workId: String
        var title: String
        var localGloss: String?
        var localTerm: String
    }

    private var livesIn: [Occurrence] {
        (concept.appearsIn ?? []).compactMap { wid in
            guard let title = library.workTitle(id: wid) else { return nil }
            let entry = library.glossEntry(workId: wid, conceptId: concept.id)
            return Occurrence(workId: wid, title: title,
                              localGloss: entry?.gloss, localTerm: entry?.term ?? concept.term)
        }
    }

    private func workRow(_ occ: Occurrence) -> some View {
        NavigationLink(value: ReaderRoute(workId: occ.workId, target: .word(occ.localTerm))) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(occ.title)
                        .font(.system(.headline, design: .serif)).foregroundColor(pal.ink)
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        Text("Read in context").font(.caption.weight(.medium))
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                    }
                    .foregroundColor(pal.accent)
                }
                if let g = occ.localGloss {
                    Text(g).font(.footnote).foregroundColor(pal.inkSoft)
                        .lineLimit(3)
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

    private func sectionLabel(_ t: String) -> some View {
        Text(t.uppercased())
            .font(.caption2.weight(.semibold)).tracking(2).foregroundColor(pal.accent)
    }
}
