import SwiftUI

// The full provenance record for an edition — one tap from the reader. For the
// Lectio Modern Edition this shows model, vintage, date, estimated tokens, the
// sources synthesized, and the method (BIBLE.md §2–3).
struct ProvenanceSheet: View {
    let edition: Edition
    let workTitle: String
    let pal: Palette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(workTitle).font(.system(.title3, design: .serif)).foregroundColor(pal.ink)
                    Text(title).font(.subheadline).foregroundColor(pal.accent)
                }

                if edition.kind == "modern" {
                    let p = edition.provenance
                    row("Edition", "The Vernacular" + (p.vintage.map { " · \($0)" } ?? ""))
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
                    if !edition.character.isEmpty {
                        block("Character") {
                            Text(edition.character).font(.footnote).foregroundColor(pal.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Text(edition.kind == "modern"
                     ? "The Vernacular is SDIT's own edition, synthesized from public-domain sources. Not a historical translation."
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
