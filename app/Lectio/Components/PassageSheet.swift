import SwiftUI

// Shown when the reader taps a paragraph: the passage, a save control, and the
// chapter's context. (A deeper plain-language explanation arrives with the AI layer.)
struct PassageSheet: View {
    let segmentId: String
    let text: String
    let workTitle: String
    let chapterLabel: String
    let chapterOverview: String?
    let pal: Palette
    @EnvironmentObject var saved: SavedStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("This passage")
                    .font(.caption).tracking(2).foregroundColor(pal.inkSoft)

                Text(text)
                    .font(.system(size: 17, design: .serif))
                    .lineSpacing(5)
                    .foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    saved.togglePassage(SavedPassage(id: segmentId, text: text, workTitle: workTitle))
                } label: {
                    Label(saved.isPassageSaved(segmentId) ? "Saved" : "Save passage",
                          systemImage: saved.isPassageSaved(segmentId) ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.bordered)
                .tint(pal.accent)

                if let overview = chapterOverview {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WHERE THIS FALLS · \(chapterLabel.uppercased())")
                            .font(.caption2).tracking(1).foregroundColor(pal.inkSoft)
                        Text(overview)
                            .font(.footnote).foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(pal.paper)
    }
}
