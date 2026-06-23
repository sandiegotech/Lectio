import SwiftUI

// A navigable route to an overview reading view.
struct OverviewRoute: Hashable {
    var eyebrow: String?
    var title: String
    var text: String
}

// A simple reading surface for a Lectio-authored overview (e.g. the introduction to a
// collection). Serif on parchment, like the book reader, but for editorial prose.
struct OverviewReaderView: View {
    var eyebrow: String? = nil
    let title: String
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    private var pal: Palette { Palette.forScheme(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.caption).tracking(2.5).foregroundColor(pal.accent)
                }
                Text(title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 6)

                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                    paragraph(para)
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .background(pal.paper.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var paragraphs: [String] {
        text.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // A short Title-Case "Label. rest…" lead (a tour heading) renders in the accent.
    private func leadLabel(_ p: String) -> String? {
        guard let r = p.range(of: ". ") else { return nil }
        let lead = String(p[p.startIndex..<r.lowerBound])
        guard lead.count < 30,
              !lead.contains(where: \.isNumber),     // skip "In 1909 …" and abbreviations like "W."
              !lead.contains(" the ") else { return nil }
        return lead
    }

    @ViewBuilder
    private func paragraph(_ p: String) -> some View {
        if let lead = leadLabel(p), let r = p.range(of: ". ") {
            let rest = String(p[r.upperBound...])
            (Text(lead + ". ").font(.system(size: 18, design: .serif)).bold().foregroundColor(pal.accent)
             + Text(rest).font(.system(size: 18, design: .serif)).foregroundColor(pal.ink))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(p)
                .font(.system(size: 18, design: .serif))
                .lineSpacing(6)
                .foregroundColor(pal.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
