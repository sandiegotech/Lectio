import SwiftUI

// The note editor — attach a thought to a highlighted passage, so a mark can carry
// what the passage meant to you. Presented as a small sheet from the reader (right
// after highlighting), the margin rail, or the Notes page. SavedStore is passed in
// explicitly because sheets don't inherit .environmentObject.
struct NoteEditorSheet: View {
    let highlight: SavedHighlight
    let pal: Palette
    @ObservedObject var saved: SavedStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    private var hasExistingNote: Bool { !(highlight.note ?? "").isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(hasExistingNote ? "YOUR NOTE" : "ADD A NOTE")
                    .font(.caption2).tracking(2).foregroundColor(pal.accent)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                        .foregroundColor(pal.inkSoft).frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }

            // The passage the note hangs on.
            HStack(alignment: .top, spacing: 10) {
                Rectangle().fill(pal.gold).frame(width: 3)
                Text(snippet(highlight.text))
                    .font(.system(.subheadline, design: .serif)).italic()
                    .foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextEditor(text: $text)
                .focused($focused)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(pal.ink)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 120, maxHeight: 220)
                .background(RoundedRectangle(cornerRadius: 10).fill(pal.paper))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(pal.rule))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("What does this passage mean to you?")
                            .font(.system(size: 16, design: .serif)).italic()
                            .foregroundColor(pal.inkSoft.opacity(0.55))
                            .padding(.horizontal, 13).padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                if hasExistingNote {
                    Button {
                        saved.setNote(nil, forHighlight: highlight.id)
                        dismiss()
                    } label: {
                        Text("Remove note").font(.subheadline)
                            .foregroundColor(pal.accent)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button {
                    saved.setNote(text, forHighlight: highlight.id)
                    dismiss()
                } label: {
                    Text("Save").font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 9)
                        .background(Capsule().fill(pal.accent))
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasExistingNote)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(pal.rail.ignoresSafeArea())
        .onAppear {
            text = highlight.note ?? ""
            focused = true
        }
    }

    private func snippet(_ t: String) -> String {
        let clean = t.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count > 160 ? "“" + clean.prefix(160).trimmingCharacters(in: .whitespaces) + "…”"
                                 : "“" + clean + "”"
    }
}
