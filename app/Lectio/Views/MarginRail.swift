import SwiftUI

// The reader's own marks — saved words and highlighted passages — embedded at
// the foot of the Docent panel. Tapping one jumps to it in the text. Renders
// nothing when nothing is saved (no empty state on purpose).
struct MarginRail: View {
    let work: Work
    let pal: Palette
    var onJump: (String) -> Void = { _ in }          // jump to a segment id
    var onWordJump: (String) -> Void = { _ in }      // jump to where a saved word appears

    @EnvironmentObject var saved: SavedStore

    var body: some View {
        let highlights = saved.highlights(forWork: work.id)
        let words = saved.words(forWork: work.id)
        VStack(alignment: .leading, spacing: 22) {
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
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(highlights) { h in
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
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
