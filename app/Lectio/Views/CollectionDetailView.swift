import SwiftUI
import UIKit

// A collection's own page: what it is, why it exists, the backstory — then the books.
struct CollectionDetailView: View {
    let collection: BookCollection
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var colorScheme
    private var pal: Palette { Palette.forScheme(colorScheme) }

    // In-copyright works never appear on a collection page — they surface only in the
    // timeline's unlockable section and in Search.
    private var visibleShells: [BookCollection.Planned] {
        (collection.planned ?? []).filter { !$0.isLocked }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    if let g = collection.group {
                        Text(g.uppercased()).font(.caption2).tracking(2).foregroundColor(pal.accent)
                    }
                    Text(collection.title)
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundColor(pal.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(collection.curator)  ·  \(library.works(in: collection).count + visibleShells.count) works")
                        .font(.system(.subheadline, design: .serif)).italic()
                        .foregroundColor(pal.inkSoft)
                }

                ForEach(Array(aboutParagraphs.enumerated()), id: \.offset) { _, para in
                    Text(para)
                        .font(.system(size: 16, design: .serif))
                        .lineSpacing(5)
                        .foregroundColor(pal.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let introURL = library.collectionImageURL(collection.id),
                   let img = UIImage(contentsOfFile: introURL.path) {
                    introBanner(img)
                } else if let intro = collection.introduction, !intro.isEmpty {
                    overviewLink(intro)
                }

                Rectangle().fill(pal.rule).frame(height: 1).padding(.vertical, 6)

                Text("The books".uppercased())
                    .font(.caption2).tracking(2).foregroundColor(pal.inkSoft)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(library.works(in: collection)) { work in
                        NavigationLink(value: bookOverview(work)) { workRow(work) }.buttonStyle(.plain)
                    }
                    let shells = visibleShells
                    if shells.contains(where: { !($0.part ?? "").isEmpty }) {
                        ForEach(orderedParts(shells), id: \.self) { part in
                            if !part.isEmpty {
                                Text(part.uppercased())
                                    .font(.caption).tracking(2).foregroundColor(pal.accent)
                                    .padding(.top, 10)
                            }
                            ForEach(shells.filter { ($0.part ?? "") == part }, id: \.title) { shell in
                                NavigationLink(value: bookOverview(shell: shell)) { shellRow(shell) }.buttonStyle(.plain)
                            }
                        }
                    } else {
                        ForEach(shells, id: \.title) { shell in
                            NavigationLink(value: bookOverview(shell: shell)) { shellRow(shell) }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 26)
            .padding(.vertical, 18)
        }
        .background(pal.paper.ignoresSafeArea())
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func introBanner(_ img: UIImage) -> some View {
        let readable = !(collection.introduction ?? "").isEmpty
        let card = HStack(alignment: .top, spacing: 16) {
            Image(uiImage: img)
                .resizable().scaledToFit()
                .frame(width: 116)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.24), radius: 7, y: 4)
            VStack(alignment: .leading, spacing: 7) {
                Text("THE INTRODUCTION").font(.caption2).tracking(2).foregroundColor(pal.accent)
                Text("A Lectio overview of the set — what it is, why it exists, and how to read it.")
                    .font(.system(.subheadline, design: .serif)).foregroundColor(pal.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if readable {
                    HStack(spacing: 4) {
                        Text("Read the introduction").font(.caption.weight(.medium))
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                    }
                    .foregroundColor(pal.accent)
                } else {
                    Text("Reading edition coming soon").font(.caption).foregroundColor(pal.inkSoft)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(pal.rail))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.rule))
        .padding(.top, 4)

        if readable, let intro = collection.introduction {
            NavigationLink(value: OverviewRoute(eyebrow: "An Introduction", title: collection.title, text: intro)) {
                card
            }
            .buttonStyle(.plain)
        } else {
            card
        }
    }

    // MARK: annotated rows

    private func bookOverview(_ w: Work) -> BookOverview {
        BookOverview(title: w.title, author: w.author, era: w.composed,
                     overview: w.blurb, workId: w.id, coverPath: nil, tradition: w.tradition)
    }

    private func bookOverview(shell p: BookCollection.Planned) -> BookOverview {
        BookOverview(title: p.title, author: p.author ?? "", era: p.era ?? "",
                     overview: p.note ?? "", workId: nil, coverPath: p.cover, tradition: p.tradition)
    }

    private func workRow(_ work: Work) -> some View {
        bookRow(thumb: AnyView(workThumb(work)),
                title: work.title,
                sub: [work.author, work.composed].filter { !$0.isEmpty }.joined(separator: " · "),
                overview: work.blurb,
                inLibrary: true)
    }

    private func shellRow(_ p: BookCollection.Planned) -> some View {
        let sub = [p.author ?? "", p.era ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
        return bookRow(thumb: AnyView(plannedThumb(p)), title: p.title, sub: sub,
                       overview: p.note ?? "", inLibrary: false)
    }

    private func bookRow(thumb: AnyView, title: String, sub: String, overview: String, inLibrary: Bool) -> some View {
        HStack(alignment: .top, spacing: 13) {
            thumb.frame(width: 48, height: 70)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(.headline, design: .serif)).foregroundColor(pal.ink)
                if !sub.isEmpty {
                    Text(sub).font(.caption).foregroundColor(pal.accent.opacity(0.85))
                }
                statusTag(inLibrary)
                if !overview.isEmpty {
                    Text(overview).font(.footnote).foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                .foregroundColor(pal.inkSoft.opacity(0.55)).padding(.top, 4)
        }
        .contentShape(Rectangle())
    }

    private func statusTag(_ inLibrary: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: inLibrary ? "checkmark.circle.fill" : "hourglass").font(.system(size: 9))
            Text(inLibrary ? "In the library" : "Coming soon").font(.caption2.weight(.medium))
        }
        .foregroundColor(inLibrary ? pal.accent : pal.inkSoft)
    }

    @ViewBuilder
    private func workThumb(_ work: Work) -> some View {
        if let url = library.coverURL(work.id), let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: 48, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
        } else {
            SpineCard(work: work, height: 70).frame(width: 48)
        }
    }

    private func shellThumb(tradition: String?) -> some View {
        let isEast = tradition == "East"
        let fill = isEast ? Color(hex: 0x071118).opacity(0.96) : pal.paper.opacity(0.5)
        let stroke = isEast ? Color(hex: 0xB58A3B).opacity(0.72) : pal.rule
        let icon = isEast ? Color(hex: 0xD3B06A).opacity(0.68) : pal.inkSoft.opacity(0.5)
        return RoundedRectangle(cornerRadius: 4)
            .fill(fill)
            .overlay(RoundedRectangle(cornerRadius: 4)
                .strokeBorder(stroke, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
            .overlay(Image(systemName: "hourglass").font(.system(size: 13))
                .foregroundColor(icon))
    }

    @ViewBuilder
    private func plannedThumb(_ planned: BookCollection.Planned) -> some View {
        if let url = library.plannedCoverURL(previewCoverPath(for: planned)), let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: 48, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
        } else {
            shellThumb(tradition: planned.tradition)
        }
    }

    private func previewCoverPath(for planned: BookCollection.Planned) -> String? {
        // Always the Lectio (western) cover, for a consistent theme across every shelf —
        // including Harvard Classics, where we used to swap in the red Harvard-edition cover.
        planned.cover
    }

    private func orderedParts(_ shells: [BookCollection.Planned]) -> [String] {
        var seen = Set<String>(); var out: [String] = []
        for s in shells {
            let p = s.part ?? ""
            if !seen.contains(p) { seen.insert(p); out.append(p) }
        }
        return out
    }

    private func overviewLink(_ intro: String) -> some View {
        NavigationLink(value: OverviewRoute(eyebrow: "An Introduction", title: collection.title, text: intro)) {
            HStack(spacing: 10) {
                Image(systemName: "text.book.closed").foregroundColor(pal.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Read the overview").font(.subheadline.weight(.medium)).foregroundColor(pal.accent)
                    Text("A Lectio introduction to the collection").font(.caption).foregroundColor(pal.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundColor(pal.inkSoft)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(pal.rail))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.rule))
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    private var aboutParagraphs: [String] {
        (collection.about ?? collection.blurb).components(separatedBy: "\n\n")
    }
}
