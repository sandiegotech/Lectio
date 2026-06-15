import SwiftUI

struct ReaderView: View {
    let work: Work
    @EnvironmentObject var library: Library
    @Environment(\.dismiss) private var dismiss

    @State private var mode: ReaderMode = .natural
    @State private var focus = false
    @State private var sectionIndex = 0

    private var edition: Edition? { library.edition(for: work) }

    var body: some View {
        let pal = Palette.of(mode)
        GeometryReader { geo in
            let wide = geo.size.width > 680
            VStack(spacing: 0) {
                header(pal: pal)
                Divider().overlay(pal.rule)

                if let edition, edition.sections.indices.contains(sectionIndex) {
                    let section = edition.sections[sectionIndex]
                    let showRail = wide && !focus
                    HStack(alignment: .top, spacing: 0) {
                        readingColumn(section: section, pal: pal)
                        if showRail {
                            MarginRail(
                                work: work,
                                section: section,
                                edition: edition,
                                pal: pal,
                                progress: Double(sectionIndex + 1) / Double(edition.sections.count)
                            )
                            .frame(width: max(220, geo.size.width * 0.28))
                            .background(pal.rail)
                        }
                    }
                } else {
                    Spacer()
                    Text("No edition available.").foregroundStyle(pal.inkSoft)
                    Spacer()
                }

                Divider().overlay(pal.rule)
                footer(pal: pal)
            }
            .background(pal.paper)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: header

    private func header(pal: Palette) -> some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.body.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(pal.inkSoft)

            VStack(alignment: .leading, spacing: 1) {
                Text(work.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(pal.ink)
                Text(editionByline)
                    .font(.caption2)
                    .foregroundStyle(pal.inkSoft)
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(ReaderMode.allCases) { m in
                    pill(m.rawValue, active: mode == m, pal: pal) { mode = m }
                }
                Rectangle().fill(pal.rule).frame(width: 1, height: 18)
                pill("Focus", systemImage: "rectangle", active: focus, pal: pal) {
                    focus.toggle()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(pal.paper)
    }

    private var editionByline: String {
        guard let e = edition else { return work.author }
        var parts = [work.author]
        if let t = e.translator { parts.append(t) }
        if let y = e.publishedYear { parts.append(String(y)) }
        return parts.joined(separator: " · ")
    }

    private func pill(_ title: String, systemImage: String? = nil, active: Bool,
                      pal: Palette, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage).font(.caption2) }
                Text(title).font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(active ? pal.accent : pal.paper)
            .foregroundStyle(active ? Color.white : pal.ink)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(pal.rule))
        }
        .buttonStyle(.plain)
    }

    // MARK: reading column

    private func readingColumn(section: Section, pal: Palette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Menu {
                    ForEach(Array((edition?.sections ?? []).enumerated()), id: \.element.id) { idx, s in
                        Button(s.label) { sectionIndex = idx }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(section.label.uppercased()).font(.caption).tracking(2)
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .foregroundStyle(pal.accent)
                }

                if let title = section.title {
                    Text(title)
                        .font(.system(.title3, design: .serif)).italic()
                        .foregroundStyle(pal.ink)
                }

                ForEach(section.segments) { segment in
                    Text(segment.text)
                        .font(.system(size: 19, design: .serif))
                        .lineSpacing(7)
                        .foregroundStyle(pal.ink)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 660, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
        }
    }

    // MARK: footer

    private func footer(pal: Palette) -> some View {
        HStack {
            if let p = edition?.provenance {
                Label("Public domain · \(provenanceSource(p))", systemImage: "checkmark.shield")
                    .font(.caption2)
                    .foregroundStyle(pal.inkSoft)
            }
            Spacer()
            if let e = edition, e.sections.indices.contains(sectionIndex) {
                Text("\(e.sections[sectionIndex].label) · \(e.sections[sectionIndex].segments.count) segments")
                    .font(.caption2)
                    .foregroundStyle(pal.inkSoft)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(pal.paper)
    }

    private func provenanceSource(_ p: Provenance) -> String {
        switch p.source {
        case "gutenberg": return "Project Gutenberg" + (p.sourceId.map { " #\($0)" } ?? "")
        case "standard_ebooks": return "Standard Ebooks"
        case "wikisource": return "Wikisource"
        default: return p.source.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
