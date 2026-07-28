import SwiftUI

// The Docent's panel: the anchored passage up top, the conversation below,
// a question field at the bottom. Quiet, serif, honest about being AI.
struct DocentPanel: View {
    let work: Work
    let pal: Palette
    @ObservedObject var docent: DocentService
    // Observed separately so streaming tokens re-render only this panel.
    @ObservedObject var thread: DocentThread
    // Re-anchor to what's on screen now (the conversation follows the reader).
    var onReanchor: () -> Void = {}

    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    private static let openers = [
        "Explain this passage",
        "What's the context here?",
        "Why does this matter?",
    ]

    var body: some View {
        VStack(spacing: 0) {
            if docent.isAvailable, let ctx = docent.context {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            passageBlock(ctx)
                            if thread.exchanges.isEmpty {
                                openerChips
                            }
                            ForEach(thread.exchanges) { ex in
                                exchangeBlock(ex)
                            }
                            Color.clear.frame(height: 1).id("docent-end")
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // Scroll on new questions and on completion — not per token,
                    // which hammered layout during streaming.
                    .onChange(of: thread.exchanges.count) { _, _ in
                        proxy.scrollTo("docent-end", anchor: .bottom)
                    }
                    .onChange(of: thread.busy) { _, isBusy in
                        if !isBusy { proxy.scrollTo("docent-end", anchor: .bottom) }
                    }
                }
                Divider().overlay(pal.rule)
                inputBar
                footer
            } else {
                unavailableNote
            }
        }
        .onAppear { docent.refresh() }
    }

    // MARK: anchored passage

    @ViewBuilder
    private func passageBlock(_ ctx: DocentContext) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("ON \(ctx.sectionLabel.uppercased())")
                    .font(.caption2).tracking(1).foregroundColor(pal.inkSoft)
                Spacer()
                Button(action: onReanchor) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.to.line").font(.system(size: 9))
                        Text("Follow me").font(.caption2)
                    }
                    .foregroundColor(pal.inkSoft)
                }
                .buttonStyle(.plain)
            }
            // No added quote marks — passages often carry their own.
            Text(snippet(ctx.passage))
                .font(.system(.footnote, design: .serif))
                .italic()
                .foregroundColor(pal.inkSoft)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(pal.rule).frame(height: 1)
        }
    }

    private var openerChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(Self.openers, id: \.self) { q in
                Button { docent.ask(q) } label: {
                    Text(q)
                        .font(.caption).foregroundColor(pal.accent)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(pal.paper)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(pal.rule))
                }
                .buttonStyle(.plain)
                .disabled(thread.busy)
            }
        }
    }

    // MARK: conversation

    @ViewBuilder
    private func exchangeBlock(_ ex: DocentExchange) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ex.question)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(pal.accent)
                .fixedSize(horizontal: false, vertical: true)
            if ex.answer.isEmpty && !ex.done {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small).tint(pal.inkSoft)
                    Text("Reading…").font(.caption).foregroundColor(pal.inkSoft)
                }
            } else {
                Text(ex.answer)
                    .font(.system(.callout, design: .serif))
                    .lineSpacing(4)
                    .foregroundColor(ex.failed ? pal.inkSoft : pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: input + footer

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask about this passage…", text: $draft, axis: .vertical)
                .font(.system(.callout, design: .serif))
                .foregroundColor(pal.ink)
                .lineLimit(1...4)
                .focused($fieldFocused)
                .onSubmit(send)
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundColor(canSend ? pal.accent : pal.inkSoft.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(pal.paper)
    }

    private var canSend: Bool {
        !thread.busy && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        guard canSend else { return }
        docent.ask(draft)
        draft = ""
    }

    private var footer: some View {
        Text("Answers are AI-generated on this device\(docent.providerLabel.map { " (\($0))" } ?? "") and may err. The text is the authority.")
            .font(.system(size: 10))
            .foregroundColor(pal.inkSoft.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14).padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(pal.paper)
    }

    // The Ask space is always here — when the model isn't, it says why and how
    // to bring it back, and re-checks on demand.
    private var unavailableNote: some View {
        VStack(spacing: 14) {
            Image(systemName: "questionmark.bubble")
                .font(.title2).foregroundColor(pal.inkSoft.opacity(0.5))
            Text("A place to ask questions about what you're reading — answered by an on-device model, private to this device.")
                .font(.callout).foregroundColor(pal.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text({
                if case .unavailable(let reason) = docent.availability { return reason }
                return "The \(DocentFeature.name) isn't available."
            }())
                .font(.footnote).foregroundColor(pal.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button { docent.refresh() } label: {
                Text("Check again")
                    .font(.caption.weight(.medium)).foregroundColor(pal.accent)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .overlay(Capsule().stroke(pal.accent.opacity(0.4)))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private func snippet(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count > 220 ? String(clean.prefix(220)).trimmingCharacters(in: .whitespaces) + "…" : clean
    }
}
