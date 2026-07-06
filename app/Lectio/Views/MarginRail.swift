import SwiftUI

// The Margin: the side rail that carries the living layer beside the text — where you
// are in the book, the people in this passage, its editorial notes and connections —
// followed by the reader's own marks (saved words, highlights, and their notes).
// Enrichment comes from the work's enrichment.json; marks from SavedStore.
struct MarginRail: View {
    let work: Work
    var section: Section? = nil                      // the section currently in view
    let pal: Palette
    var onJump: (String) -> Void = { _ in }          // jump to a segment id
    var onWordJump: (String) -> Void = { _ in }      // jump to where a saved word appears

    @EnvironmentObject var saved: SavedStore
    @EnvironmentObject var library: Library
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var expandedPerson: String?
    @State private var noteTarget: SavedHighlight?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                livingLayer
                marksLayer
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(alignment: .leading) {
            Rectangle().fill(pal.rule).frame(width: 1)
        }
        .sheet(item: $noteTarget) { h in
            NoteEditorSheet(highlight: h, pal: pal, saved: saved)
                .presentationDetents([.medium])
        }
    }

    // MARK: the living layer — editorial enrichment for the passage in view

    @ViewBuilder
    private var livingLayer: some View {
        if let sec = section {
            let passage = library.passage(workId: work.id, sectionId: sec.id)

            if let overview = library.chapterOverview(workId: work.id, order: sec.order),
               !overview.isEmpty {
                railSection("Where you are") {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(sectionName(sec))
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .foregroundColor(pal.ink)
                        Text(overview)
                            .font(.footnote).foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let people = passage?.people, !people.isEmpty {
                railSection("People here") {
                    VStack(alignment: .leading, spacing: 8) {
                        FlowLayout(spacing: 6) {
                            ForEach(people, id: \.self) { name in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        expandedPerson = expandedPerson == name ? nil : name
                                    }
                                } label: { personChip(name, active: expandedPerson == name) }
                                .buttonStyle(.plain)
                            }
                        }
                        if let name = expandedPerson, people.contains(name) {
                            personCard(name)
                        }
                    }
                }
            }

            if let defines = passage?.define, !defines.isEmpty {
                railSection("In this passage") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(defines, id: \.self) { d in
                            HStack(alignment: .top, spacing: 6) {
                                Text(d.term)
                                    .font(.footnote.weight(.semibold)).foregroundColor(pal.ink)
                                Text(d.gloss)
                                    .font(.footnote).foregroundColor(pal.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }

            if let conns = passage?.connections, !conns.isEmpty {
                railSection("Connections") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(conns, id: \.self) { connectionRow($0) }
                    }
                }
            }
        }
    }

    private func sectionName(_ sec: Section) -> String {
        if let t = sec.title, !t.isEmpty { return "\(sec.label) — \(t)" }
        return sec.label
    }

    private func personChip(_ name: String, active: Bool) -> some View {
        Text(name)
            .font(.caption).foregroundColor(active ? pal.paper : pal.ink)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(active ? pal.accent : pal.paper)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(active ? pal.accent : pal.rule))
    }

    // The tapped person's curated gloss, with a jump to where they appear in the text.
    private func personCard(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let entry = library.glossEntry(workId: work.id, term: name) {
                Text(entry.gloss)
                    .font(.footnote).foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No note on \(name) yet.")
                    .font(.footnote).foregroundColor(pal.inkSoft)
            }
            Button { onWordJump(name) } label: {
                HStack(spacing: 4) {
                    Image(systemName: "text.magnifyingglass").font(.caption2)
                    Text("Find in text").font(.caption.weight(.medium))
                }
                .foregroundColor(pal.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(pal.paper))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(pal.rule))
    }

    @ViewBuilder
    private func connectionRow(_ conn: Enrichment.Connection) -> some View {
        let row = HStack(alignment: .top, spacing: 7) {
            Image(systemName: connectionIcon(conn.kind))
                .font(.caption2).foregroundColor(pal.accent)
                .padding(.top, 2).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(conn.label)
                    .font(.footnote.weight(.medium)).foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(conn.kind.capitalized)
                    .font(.caption2).foregroundColor(pal.inkSoft)
            }
            Spacer(minLength: 0)
        }
        // A connection to another book navigates to its overview — but only where the
        // rail lives inside the navigation stack (the iPad drawer; the iPhone panel is
        // a sheet with no stack, so the row stays informational there).
        if hSize == .regular, conn.kind == "work",
           let target = library.bookOverview(title: conn.label) {
            NavigationLink(value: target) { row }.buttonStyle(.plain)
        } else {
            row
        }
    }

    private func connectionIcon(_ kind: String) -> String {
        switch kind {
        case "author": return "person"
        case "idea":   return "lightbulb"
        case "work":   return "book.closed"
        case "place":  return "map"
        default:        return "link"
        }
    }

    // MARK: the reader's own marks

    @ViewBuilder
    private var marksLayer: some View {
        let highlights = saved.highlights(forWork: work.id)
        let words = saved.words(forWork: work.id)

        if highlights.isEmpty && words.isEmpty {
            railSection("Your marks") {
                Text("Save a word from the popup, or press and hold to highlight a passage — then add a note on what it means to you. They'll collect here.")
                    .font(.footnote).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        if !words.isEmpty {
            railSection("Saved words") {
                FlowLayout(spacing: 6) {
                    ForEach(words) { w in
                        Button { onWordJump(w.term) } label: { chip(w.term) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }

        if !highlights.isEmpty {
            railSection("Highlights") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(highlights) { h in highlightRow(h) }
                }
            }
        }
    }

    @ViewBuilder
    private func highlightRow(_ h: SavedHighlight) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 6) {
                Button { onJump(h.segmentId) } label: {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "highlighter")
                            .font(.caption2).foregroundColor(pal.gold)
                        Text(snippet(h.text))
                            .font(.system(.footnote, design: .serif))
                            .foregroundColor(pal.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                Button { noteTarget = h } label: {
                    Image(systemName: h.note == nil ? "square.and.pencil" : "note.text")
                        .font(.caption)
                        .foregroundColor(h.note == nil ? pal.inkSoft.opacity(0.7) : pal.accent)
                        .frame(width: 24, height: 20)
                }
                .buttonStyle(.plain)
            }
            if let note = h.note {
                HStack(alignment: .top, spacing: 8) {
                    Rectangle().fill(pal.gold.opacity(0.6)).frame(width: 2)
                    Text(note)
                        .font(.system(.caption, design: .serif)).italic()
                        .foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 18)
            }
        }
        .contextMenu {
            Button { noteTarget = h } label: {
                Label(h.note == nil ? "Add note" : "Edit note", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) { saved.removeHighlight(id: h.id) } label: {
                Label("Remove highlight", systemImage: "trash")
            }
        }
    }

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
        HStack(spacing: 4) {
            Image(systemName: "bookmark.fill").font(.system(size: 8)).foregroundColor(pal.gold)
            Text(text).font(.caption).foregroundColor(pal.ink)
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(pal.paper)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(pal.rule))
    }

    private func snippet(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count > 90 ? "“" + clean.prefix(90).trimmingCharacters(in: .whitespaces) + "…”"
                                : "“" + clean + "”"
    }
}
