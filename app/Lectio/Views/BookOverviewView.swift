import SwiftUI
import UIKit

// A navigable "learn more" page for any book — works already in the library and shells
// not yet added. The status line tells you which it is; in-library books offer "Read now".
struct BookOverview: Hashable {
    var title: String
    var author: String
    var era: String
    var overview: String
    var workId: String?     // non-nil ⇒ in the library (readable)
    var coverPath: String?  // planned-cover path for shells
    var tradition: String? = nil
}

struct BookOverviewView: View {
    let book: BookOverview
    @EnvironmentObject var library: Library
    @EnvironmentObject var saved: SavedStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCoverPreview = false
    private var pal: Palette { Palette.forScheme(colorScheme) }

    private let coverW: CGFloat = 132
    private let coverH: CGFloat = 196

    private var inLibrary: Bool { book.workId != nil }
    private var work: Work? { book.workId.flatMap { id in library.works.first { $0.id == id } } }
    private var explore: ExploreRecord? { library.explore.first { $0.title == book.title } }

    private var sub: String {
        [book.author, book.era].filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }

    // Every shelf, list, and genre this book appears on — each tappable to browse it.
    private var appearsIn: [BookCollection] {
        library.collections.filter { c in
            library.works(in: c).contains { $0.title == book.title }
                || (c.planned ?? []).contains { $0.title == book.title }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    coverView
                    VStack(alignment: .leading, spacing: 7) {
                        Text(book.title)
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundColor(pal.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if !sub.isEmpty {
                            Text(sub).font(.system(.subheadline, design: .serif)).italic()
                                .foregroundColor(pal.inkSoft)
                        }
                        statusBadge
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    if inLibrary, let w = work {
                        NavigationLink(value: w) { actionButton("book", "Read now", filled: true) }
                            .buttonStyle(.plain)
                    }
                    Button {
                        saved.toggleCollection(SavedBook(title: book.title, author: book.author))
                    } label: {
                        let inColl = saved.isInCollection(book.title)
                        actionButton(inColl ? "checkmark" : "plus",
                                     inColl ? "In your collection" : "Check out", filled: false)
                    }
                    .buttonStyle(.plain)
                }

                Label(inLibrary ? "On your tablet · available offline"
                                : "In the cloud · the full text arrives when this edition is published",
                      systemImage: inLibrary ? "ipad" : "icloud")
                    .font(.caption2).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                Rectangle().fill(pal.rule).frame(height: 1).padding(.vertical, 2)

                if let ex = explore {
                    Text("\u{201C}\(ex.quote)\u{201D}")
                        .font(.system(size: 20, design: .serif)).lineSpacing(4)
                        .foregroundColor(pal.ink).fixedSize(horizontal: false, vertical: true)
                    Text(ex.source).font(.caption2).foregroundColor(pal.inkSoft.opacity(0.8))
                }

                if !book.overview.isEmpty {
                    ForEach(Array(book.overview.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, para in
                        Text(para)
                            .font(.system(size: 17, design: .serif))
                            .lineSpacing(6)
                            .foregroundColor(pal.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !inLibrary {
                    Text("This work isn't in the library yet. A clear modern Lectio edition — read by default, with the public-domain translations and the original a tap away — is on the way.")
                        .font(.footnote).foregroundColor(pal.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(pal.rail))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.rule))
                }

                if let ex = explore, ex.original?.isEmpty == false || ex.translationNote?.isEmpty == false {
                    sectionLabel("ON THE TEXT")
                    if let o = ex.original, !o.isEmpty { onTextRow("text.book.closed", o) }
                    if let tn = ex.translationNote, !tn.isEmpty { onTextRow("quote.bubble", tn) }
                }

                if let ex = explore, !ex.connections.isEmpty {
                    sectionLabel("THREADS")
                    ForEach(Array(ex.connections.enumerated()), id: \.offset) { _, c in threadRow(c) }
                }

                if !appearsIn.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("APPEARS IN").font(.caption2).tracking(2).foregroundColor(pal.inkSoft)
                        FlowChips(collections: appearsIn, pal: pal)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 26)
            .padding(.vertical, 20)
        }
        .background(pal.paper.ignoresSafeArea())
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCoverPreview) {
            if let img = coverUIImage { CoverPreview(image: img) }
        }
        .onAppear {
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_PREVIEW"] != nil, coverUIImage != nil {
                showCoverPreview = true
            }
        }
    }

    private func actionButton(_ icon: String, _ text: String, filled: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(text).font(.subheadline.weight(.medium))
        }
        .foregroundColor(filled ? .white : pal.accent)
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Capsule().fill(filled ? pal.accent : pal.accent.opacity(0.12)))
        .overlay(Capsule().stroke(filled ? Color.clear : pal.accent.opacity(0.35)))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption2).tracking(2).foregroundColor(pal.inkSoft).padding(.top, 4)
    }

    private func onTextRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon).font(.caption2).foregroundColor(pal.inkSoft.opacity(0.7))
                .padding(.top, 2).frame(width: 16)
            Text(text).font(.caption).foregroundColor(pal.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func threadRow(_ conn: ExploreRecord.Link) -> some View {
        let row = HStack(alignment: .top, spacing: 8) {
            Image(systemName: threadIcon(conn.type)).font(.caption2).foregroundColor(pal.accent)
                .padding(.top, 2).frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(conn.to).font(.subheadline.weight(.medium)).foregroundColor(pal.accent)
                Text(conn.note).font(.caption2).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        if let target = library.bookOverview(title: conn.to) {
            NavigationLink(value: target) { row }.buttonStyle(.plain)
        } else { row }
    }

    private func threadIcon(_ type: String) -> String {
        switch type {
        case "influences": return "arrow.right"
        case "responds-to": return "arrowshape.turn.up.left"
        case "contrasts": return "arrow.left.and.right"
        case "parallel": return "equal"
        default: return "link"
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: inLibrary ? "checkmark.circle.fill" : "hourglass")
                .font(.caption2)
            Text(inLibrary ? "In the library" : "Coming soon")
                .font(.caption.weight(.medium))
        }
        .foregroundColor(inLibrary ? pal.accent : pal.inkSoft)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(Capsule().fill(inLibrary ? pal.accent.opacity(0.12) : pal.rail))
        .overlay(Capsule().stroke(inLibrary ? pal.accent.opacity(0.3) : pal.rule))
    }

    // The cover's image, if one exists (real-work cover or planned-shell cover).
    private var coverUIImage: UIImage? {
        if let id = book.workId, let url = library.coverURL(id) { return UIImage(contentsOfFile: url.path) }
        if let path = book.coverPath, let url = library.plannedCoverURL(path) { return UIImage(contentsOfFile: url.path) }
        return nil
    }

    @ViewBuilder
    private var coverView: some View {
        if let img = coverUIImage {
            Button { showCoverPreview = true } label: {
                coverImage(img)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                            .font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                            .padding(6).background(Circle().fill(Color.black.opacity(0.45)))
                            .padding(7)
                    }
            }
            .buttonStyle(.plain)
        } else if let w = work {
            SpineCard(work: w, height: coverH).frame(width: coverW)
        } else {
            let isEast = book.tradition == "East"
            let fill = isEast ? Color(hex: 0x071118).opacity(0.96) : pal.paper.opacity(0.5)
            let stroke = isEast ? Color(hex: 0xB58A3B).opacity(0.72) : pal.rule
            let icon = isEast ? Color(hex: 0xD3B06A).opacity(0.68) : pal.inkSoft.opacity(0.5)
            RoundedRectangle(cornerRadius: 6)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(stroke, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                .overlay(Image(systemName: "hourglass").font(.title2)
                    .foregroundColor(icon))
                .frame(width: coverW, height: coverH)
        }
    }

    private func coverImage(_ img: UIImage) -> some View {
        Image(uiImage: img).resizable().scaledToFill()
            .frame(width: coverW, height: coverH)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.24), radius: 8, y: 4)
    }
}

// Full-screen cover preview — pinch or double-tap to zoom, ✕ to close.
struct CoverPreview: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable().scaledToFit()
                .scaleEffect(scale)
                .padding(20)
                .gesture(
                    MagnificationGesture()
                        .onChanged { v in scale = min(max(lastScale * v, 1), 5) }
                        .onEnded { _ in lastScale = scale }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scale = scale > 1 ? 1 : 2.5
                        lastScale = scale
                    }
                }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(16)
            }
            .buttonStyle(.plain)
        }
    }
}

// A wrapping row of tappable collection chips — each opens that list/shelf.
struct FlowChips: View {
    let collections: [BookCollection]
    let pal: Palette

    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(collections, id: \.id) { c in
                NavigationLink(value: c) {
                    Text(c.title)
                        .font(.caption).foregroundColor(pal.inkSoft)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(pal.rail))
                        .overlay(Capsule().stroke(pal.rule))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
