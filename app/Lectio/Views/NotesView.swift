import SwiftUI

// The reader's own marks across every book — saved words and highlights — gathered in
// one place, off the library shelves. Tapping any one opens the book at that spot.
// (Later this is where an SDIT account would sync notes with Gloss / Slate — see
// AccountSync.swift; the Connect-an-app surface will live here, not on the shelves.)
struct NotesView: View {
    @EnvironmentObject var saved: SavedStore
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var colorScheme
    @State private var noteTarget: SavedHighlight?
    private var pal: Palette { Palette.forScheme(colorScheme) }

    var body: some View {
        ScrollView {
            let words = saved.items
            let highlights = saved.highlights
            VStack(alignment: .leading, spacing: 24) {
                Text("Your Notes")
                    .font(.system(.largeTitle, design: .serif)).foregroundColor(pal.ink)
                    .padding(.top, 8)

                if !saved.collection.isEmpty {
                    sectionLabel("My Collection")
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(saved.collection) { collectionRow($0) }
                    }
                }

                if words.isEmpty && highlights.isEmpty && saved.collection.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nothing saved yet.")
                            .font(.system(.title3, design: .serif)).foregroundColor(pal.ink)
                        Text("Tap a word to look it up and save it, or press and hold a passage to highlight it — then add a note on what it means to you. Everything you keep gathers here.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }

                if !words.isEmpty {
                    sectionLabel("Saved words")
                    FlowLayout(spacing: 8) {
                        ForEach(words) { w in wordChip(w) }
                    }
                }

                if !highlights.isEmpty {
                    sectionLabel("Highlights")
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(highlights) { h in highlightRow(h) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(pal.paper.ignoresSafeArea())
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $noteTarget) { h in
            NoteEditorSheet(highlight: h, pal: pal, saved: saved)
                .presentationDetents([.medium])
        }
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t.uppercased()).font(.caption2).tracking(1.5).foregroundColor(pal.inkSoft)
    }

    private func collectionRow(_ b: SavedBook) -> some View {
        let row = HStack(spacing: 11) {
            Image(systemName: "books.vertical.fill").font(.subheadline)
                .foregroundColor(pal.accent.opacity(0.8)).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(b.title).font(.system(.headline, design: .serif)).foregroundColor(pal.ink)
                if !b.author.isEmpty {
                    Text(b.author).font(.caption).foregroundColor(pal.inkSoft)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                .foregroundColor(pal.inkSoft.opacity(0.6))
        }
        return Group {
            if let ov = library.bookOverview(title: b.title) {
                NavigationLink(value: ov) { row }.buttonStyle(.plain)
            } else {
                row
            }
        }
        .contextMenu {
            Button(role: .destructive) { saved.toggleCollection(b) } label: {
                Label("Remove from collection", systemImage: "trash")
            }
        }
    }

    private func wordChip(_ w: SavedWord) -> some View {
        let label = HStack(spacing: 5) {
            Image(systemName: "bookmark.fill").font(.system(size: 8)).foregroundColor(pal.gold)
            Text(w.term).font(.callout).foregroundColor(pal.ink)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Capsule().fill(pal.paper))
        .overlay(Capsule().stroke(pal.rule))

        return Group {
            if let wid = w.workId {
                NavigationLink(value: ReaderRoute(workId: wid, target: .word(w.term))) { label }
                    .buttonStyle(.plain)
            } else {
                label
            }
        }
        .contextMenu {
            Button(role: .destructive) { saved.remove(w.term) } label: { Label("Remove", systemImage: "trash") }
        }
    }

    private func highlightRow(_ h: SavedHighlight) -> some View {
        let row = HStack(alignment: .top, spacing: 10) {
            Image(systemName: "highlighter").font(.caption).foregroundColor(pal.gold).padding(.top, 3)
            VStack(alignment: .leading, spacing: 3) {
                Text(snippet(h.text)).font(.system(.subheadline, design: .serif)).foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let note = h.note {
                    HStack(alignment: .top, spacing: 8) {
                        Rectangle().fill(pal.gold.opacity(0.6)).frame(width: 2)
                        Text(note)
                            .font(.system(.footnote, design: .serif)).italic()
                            .foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 2)
                }
                if let t = h.workTitle { Text(t).font(.caption2).foregroundColor(pal.inkSoft) }
            }
            Spacer(minLength: 0)
            Button { noteTarget = h } label: {
                Image(systemName: h.note == nil ? "square.and.pencil" : "note.text")
                    .font(.subheadline)
                    .foregroundColor(h.note == nil ? pal.inkSoft.opacity(0.7) : pal.accent)
                    .frame(width: 28, height: 24)
            }
            .buttonStyle(.plain)
        }
        return Group {
            if let wid = h.workId {
                NavigationLink(value: ReaderRoute(workId: wid, target: .segment(h.segmentId))) { row }
                    .buttonStyle(.plain)
            } else {
                row
            }
        }
        .contextMenu {
            Button { noteTarget = h } label: {
                Label(h.note == nil ? "Add note" : "Edit note", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) { saved.removeHighlight(id: h.id) } label: { Label("Remove", systemImage: "trash") }
        }
    }

    private func snippet(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count > 140 ? "“" + clean.prefix(140).trimmingCharacters(in: .whitespaces) + "…”"
                                 : "“" + clean + "”"
    }
}
