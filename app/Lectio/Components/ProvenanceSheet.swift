import SwiftUI

// The full provenance record for an edition — one tap from the reader. For the
// Lectio Modern Edition this shows model, vintage, date, estimated tokens, the
// sources synthesized, and the method (BIBLE.md §2–3).
struct ProvenanceSheet: View {
    let edition: Edition
    let workTitle: String
    let pal: Palette
    var cast: [Enrichment.GlossEntry] = []   // the book's key players (who's who)
    var chapterNote: String? = nil           // overview of the chapter being read
    @State private var showDivergences = false
    @State private var showAllCast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(workTitle).font(.system(.title3, design: .serif)).foregroundColor(pal.ink)
                    Text(title).font(.subheadline).foregroundColor(pal.accent)
                }

                if let note = chapterNote, !note.isEmpty {
                    block("Where you are") {
                        Text(note).font(.footnote).foregroundColor(pal.ink)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !cast.isEmpty { castBlock }

                if let overview = edition.overview, !overview.isEmpty {
                    block("About this edition") {
                        Text(overview).font(.footnote).foregroundColor(pal.ink)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if edition.kind == "modern" {
                    let p = edition.provenance
                    if let divergences = edition.divergences, !divergences.isEmpty {
                        block("Where this edition differs") {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Places where the Lectio Edition departs from older translations, and why.")
                                    .font(.caption).foregroundColor(pal.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                // The full list is scholarly detail — folded away by default.
                                if showDivergences {
                                    ForEach(divergences, id: \.note) { d in divergenceRow(d) }
                                }
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { showDivergences.toggle() }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(showDivergences
                                             ? "Show less"
                                             : "Learn more — \(divergences.count) places")
                                        Image(systemName: showDivergences ? "chevron.up" : "chevron.right")
                                            .font(.caption2)
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(pal.accent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    row("Edition", "Lectio Edition" + (p.vintage.map { " · \($0)" } ?? ""))
                    if let m = p.aiModel { row("Model", m) }
                    if let d = p.retrievedDate { row("Produced", d) }
                    if let t = p.tokensEstimated { row("Tokens used", "≈ \(formatted(t)) (estimated)") }
                    if let sources = p.sourcesCited, !sources.isEmpty {
                        block("Sources consulted") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(sources, id: \.self) { s in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("·").foregroundColor(pal.gold)
                                        Text(s).font(.footnote).foregroundColor(pal.ink)
                                    }
                                }
                            }
                        }
                    }
                    if !p.rightsNote.isEmptyOrNil {
                        block("Method") {
                            Text(p.rightsNote ?? "").font(.footnote).foregroundColor(pal.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    if let t = edition.translator { row("Translator", t) }
                    if let y = edition.publishedYear { row("Year", String(y)) }
                    row("Source", sourceLabel(edition.provenance))
                    if (edition.overview?.isEmpty ?? true), !edition.character.isEmpty {
                        block("Character") {
                            Text(edition.character).font(.footnote).foregroundColor(pal.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Text(edition.kind == "modern"
                     ? "Lectio Edition is SDIT's own edition, synthesized from public-domain sources. Not a historical translation."
                     : "Public-domain edition.")
                    .font(.caption2).foregroundColor(pal.inkSoft)
                    .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(pal.paper)
    }

    private var title: String {
        switch edition.kind {
        case "modern": return "Provenance"
        case "original": return "Original text"
        default: return "Historical translation"
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label.uppercased()).font(.caption2).tracking(1).foregroundColor(pal.inkSoft)
                .frame(width: 110, alignment: .leading)
            Text(value).font(.footnote).foregroundColor(pal.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func block<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.caption2).tracking(1).foregroundColor(pal.inkSoft)
            content()
        }
    }

    // Who's who: the key people, gods, and peoples of the book, from the curated
    // glossary — so a reader always has somewhere to sort out who is who.
    private var castBlock: some View {
        block("Who's who") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(showAllCast ? cast : Array(cast.prefix(6)), id: \.term) { e in
                    castRow(e)
                }
                if cast.count > 6 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showAllCast.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showAllCast ? "Show fewer" : "All \(cast.count) names")
                            Image(systemName: showAllCast ? "chevron.up" : "chevron.right")
                                .font(.caption2)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(pal.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func castRow(_ e: Enrichment.GlossEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(e.term).font(.system(.subheadline, design: .serif)).foregroundColor(pal.accent)
                if let k = e.kind, !k.isEmpty {
                    Text(k.uppercased())
                        .font(.system(size: 9, weight: .semibold)).tracking(0.6)
                        .foregroundColor(pal.inkSoft)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().stroke(pal.rule))
                }
            }
            Text(e.gloss).font(.footnote).foregroundColor(pal.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 10)
        .overlay(alignment: .leading) {
            Rectangle().fill(pal.rule).frame(width: 2)
        }
    }

    private func divergenceRow(_ d: Edition.Divergence) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let phrase = d.phrase, !phrase.isEmpty {
                    Text(phrase).font(.system(.subheadline, design: .serif)).italic()
                        .foregroundColor(pal.accent)
                }
                if let locus = d.locus, !locus.isEmpty {
                    Text(locus).font(.caption2).foregroundColor(pal.inkSoft)
                }
            }
            (Text("Older: ").font(.caption.weight(.semibold)).foregroundColor(pal.inkSoft)
             + Text(d.older).font(.caption).foregroundColor(pal.ink))
                .fixedSize(horizontal: false, vertical: true)
            (Text("Lectio: ").font(.caption.weight(.semibold)).foregroundColor(pal.accent)
             + Text(d.lectio).font(.caption).foregroundColor(pal.ink))
                .fixedSize(horizontal: false, vertical: true)
            Text(d.note).font(.footnote).foregroundColor(pal.inkSoft)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 10)
        .overlay(alignment: .leading) {
            Rectangle().fill(pal.rule).frame(width: 2)
        }
    }

    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }

    private func sourceLabel(_ p: Provenance) -> String {
        switch p.source {
        case "gutenberg": return "Project Gutenberg" + (p.sourceId.map { " #\($0)" } ?? "")
        case "standard_ebooks": return "Standard Ebooks"
        case "wikisource": return "Wikisource"
        default: return p.source.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

private extension Optional where Wrapped == String {
    var isEmptyOrNil: Bool { self?.isEmpty ?? true }
}
