import SwiftUI

// The signature element of "The Margin": a quiet rail beside the text holding the
// living layer — people, definitions, connections, and the reading sitting. Today
// it's fed by the editorial enrichment sidecar; later by the connection graph.
struct MarginRail: View {
    let work: Work
    let section: Section
    let edition: Edition
    let pal: Palette
    let progress: Double
    @EnvironmentObject var library: Library

    private var passage: Enrichment.Passage? {
        library.passage(workId: work.id, sectionId: section.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let people = passage?.people, !people.isEmpty {
                    railSection("In this passage") {
                        FlowLayout(spacing: 6) {
                            ForEach(people, id: \.self) { person in
                                chip(person)
                            }
                        }
                    }
                }

                if let defs = passage?.define, !defs.isEmpty {
                    railSection("Define · Webster 1913") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(defs, id: \.term) { d in
                                (Text(d.term)
                                    .font(.system(.subheadline, design: .serif)).italic()
                                    .foregroundColor(pal.accent)
                                 + Text(" — \(d.gloss)")
                                    .font(.system(.footnote, design: .serif))
                                    .foregroundColor(pal.inkSoft))
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                if let conns = passage?.connections, !conns.isEmpty {
                    railSection("Connections") {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(conns, id: \.label) { c in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: c.kind == "idea" ? "lightbulb" : "arrow.up.right")
                                        .font(.caption2)
                                        .foregroundColor(pal.gold)
                                    Text(c.label)
                                        .font(.footnote)
                                        .foregroundColor(pal.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }

                railSection("Edition") {
                    Text(edition.character)
                        .font(.footnote)
                        .foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                railSection("Today's sitting") {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().stroke(pal.rule, lineWidth: 3)
                            Circle()
                                .trim(from: 0, to: max(0.04, progress))
                                .stroke(pal.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 34, height: 34)
                        Text("Book \(section.order) of \(edition.sections.count)")
                            .font(.caption)
                            .foregroundColor(pal.ink)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(alignment: .leading) {
            Rectangle().fill(pal.rule).frame(width: 1)
        }
    }

    @ViewBuilder
    private func railSection<Content: View>(_ title: String,
                                            @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2).tracking(1)
                .foregroundColor(pal.inkSoft)
            content()
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(pal.inkSoft)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(pal.paper)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(pal.rule))
    }
}
