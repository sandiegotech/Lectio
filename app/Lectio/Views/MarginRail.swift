import SwiftUI

// The signature element of "The Margin": a quiet rail beside the text holding the
// living layer — the explored word, people, definitions, connections, saved words,
// and the reading progress. Fed by the editorial enrichment sidecar today; later by
// the connection graph.
struct MarginRail: View {
    let work: Work
    let section: Section?
    let edition: Edition
    let pal: Palette
    let progress: Double
    let selectedTerm: String?
    let selectedDef: String?
    let onClearSelection: () -> Void

    @EnvironmentObject var library: Library
    @EnvironmentObject var saved: SavedStore

    private var passage: Enrichment.Passage? {
        guard let section else { return nil }
        return library.passage(workId: work.id, sectionId: section.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let term = selectedTerm {
                    selectionSection(term)
                } else {
                    railSection("Understand") {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "hand.tap").font(.caption2).foregroundColor(pal.gold)
                            Text("Press and hold any word in the text to look it up and save it.")
                                .font(.footnote).foregroundColor(pal.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if let people = passage?.people, !people.isEmpty {
                    railSection("In this passage") {
                        FlowLayout(spacing: 6) {
                            ForEach(people, id: \.self) { chip($0) }
                        }
                    }
                }

                if let defs = passage?.define, !defs.isEmpty {
                    railSection("Interesting words") {
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

                if !saved.items.isEmpty {
                    railSection("Saved words") {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(saved.items) { w in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "bookmark.fill").font(.caption2).foregroundColor(pal.gold)
                                    Text(w.term).font(.footnote).foregroundColor(pal.ink)
                                }
                            }
                        }
                    }
                }

                railSection("Edition") {
                    Text(edition.character).font(.footnote).foregroundColor(pal.inkSoft)
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
                        if let section {
                            Text("\(section.label) of \(edition.sections.count)")
                                .font(.caption).foregroundColor(pal.ink)
                        }
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

    // MARK: explored word

    private func selectionSection(_ term: String) -> some View {
        railSection("Explore") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(term).font(.system(.headline, design: .serif)).foregroundColor(pal.accent)
                    Spacer()
                    Button(action: onClearSelection) {
                        Image(systemName: "xmark").font(.caption2)
                    }
                    .buttonStyle(.plain).foregroundColor(pal.inkSoft)
                }
                if let def = selectedDef {
                    Text(def).font(.system(.footnote, design: .serif)).foregroundColor(pal.ink)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No definition yet. You can still save it.")
                        .font(.caption).foregroundColor(pal.inkSoft)
                }
                saveButton(term)
            }
        }
    }

    private func saveButton(_ term: String) -> some View {
        let isSaved = saved.isSaved(term)
        return Button {
            saved.toggle(SavedWord(term: term, definition: selectedDef ?? "", workTitle: work.title))
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark").font(.caption2)
                Text(isSaved ? "Saved" : "Save").font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(isSaved ? pal.accent : pal.paper)
            .foregroundColor(isSaved ? Color.white : pal.accent)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(pal.rule))
        }
        .buttonStyle(.plain)
    }

    // MARK: building blocks

    @ViewBuilder
    private func railSection<Content: View>(_ title: String,
                                            @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2).tracking(1).foregroundColor(pal.inkSoft)
            content()
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption).foregroundColor(pal.inkSoft)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(pal.paper)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(pal.rule))
    }
}
