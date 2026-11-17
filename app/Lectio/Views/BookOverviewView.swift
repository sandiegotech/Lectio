import SwiftUI
import UIKit

// A book's own page: what it is, its editions, and the threads to other books.
// Reached from a cover in the library; "Read now" opens the default edition (or resumes).
struct BookOverview: Hashable {
    let work: Work
    init(_ work: Work) { self.work = work }
}

struct BookOverviewView: View {
    let book: BookOverview
    @EnvironmentObject var library: Library
    @EnvironmentObject var reading: ReadingState
    @EnvironmentObject var opener: BookOpener
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCoverPreview = false
    @State private var cover = CoverFrame()
    private var pal: Palette { Palette.forScheme(colorScheme) }

    private let coverW: CGFloat = 132
    private let coverH: CGFloat = 196

    private var work: Work { book.work }
    private var explore: ExploreRecord? { library.explore.first { $0.title == work.title } }

    private var sub: String {
        [work.author, work.composed].filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    coverView
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cover.frame = $0 }
                        .opacity(opener.opening?.work.id == work.id ? 0 : 1)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(work.title)
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundColor(pal.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if !sub.isEmpty {
                            Text(sub).font(.system(.subheadline, design: .serif)).italic()
                                .foregroundColor(pal.inkSoft)
                        }
                        // Quiet tags: genre and tradition.
                        HStack(spacing: 6) {
                            ForEach([work.genre, work.tradition == "East" ? "Eastern" : "Western"], id: \.self) {
                                Text($0).font(.caption2).foregroundColor(pal.inkSoft)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .overlay(Capsule().stroke(pal.rule))
                            }
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }

                Button { opener.open(work, from: cover.frame) } label: {
                    actionButton("book", "Read now", filled: true)
                }
                .buttonStyle(.plain)

                Rectangle().fill(pal.rule).frame(height: 1).padding(.vertical, 2)

                if let ex = explore {
                    Text("\u{201C}\(ex.quote)\u{201D}")
                        .font(.system(size: 20, design: .serif)).lineSpacing(4)
                        .foregroundColor(pal.ink).fixedSize(horizontal: false, vertical: true)
                    Text(ex.source).font(.caption2).foregroundColor(pal.inkSoft.opacity(0.8))
                }

                if !work.blurb.isEmpty {
                    ForEach(Array(work.blurb.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, para in
                        Text(para)
                            .font(.system(size: 17, design: .serif))
                            .lineSpacing(6)
                            .foregroundColor(pal.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                editionsList

                if let ex = explore, ex.original?.isEmpty == false || ex.translationNote?.isEmpty == false {
                    sectionLabel("ON THE TEXT")
                    if let o = ex.original, !o.isEmpty { onTextRow("text.book.closed", o) }
                    if let tn = ex.translationNote, !tn.isEmpty { onTextRow("quote.bubble", tn) }
                }

                if let ex = explore, !ex.connections.isEmpty {
                    sectionLabel("THREADS")
                    ForEach(Array(ex.connections.enumerated()), id: \.offset) { _, c in threadRow(c) }
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 26)
            .padding(.vertical, 20)
        }
        .background(pal.paper.ignoresSafeArea())
        .navigationTitle(work.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCoverPreview) {
            if let img = coverUIImage { CoverPreview(image: img) }
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["LECTIO_DEBUG_PREVIEW"] != nil, coverUIImage != nil {
                showCoverPreview = true
            }
            #endif
        }
    }

    // Every edition of the work, labelled as the reader's edition menu labels them,
    // Lectio first; each opens the reader in that edition.
    @ViewBuilder
    private var editionsList: some View {
        let infos = library.editionInfos(for: work)
        if !infos.isEmpty {
            sectionLabel("EDITIONS")
            VStack(spacing: 0) {
                ForEach(Array(infos.enumerated()), id: \.element.id) { i, info in
                    if i > 0 { Rectangle().fill(pal.rule).frame(height: 1).padding(.leading, 14) }
                    NavigationLink(value: ReaderRoute(workId: work.id, target: .edition(info.id))) {
                        HStack(spacing: 8) {
                            Text(info.label)
                                .font(.system(.subheadline, design: .serif))
                                .foregroundColor(pal.ink)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold)).foregroundColor(pal.inkSoft)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(pal.rail))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(pal.rule))
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
        let target = library.bookOverview(title: conn.to)
        let row = HStack(alignment: .top, spacing: 8) {
            Image(systemName: threadIcon(conn.type)).font(.caption2).foregroundColor(pal.accent)
                .padding(.top, 2).frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(conn.to).font(.subheadline.weight(.medium))
                    .foregroundColor(target == nil ? pal.ink : pal.accent)
                Text(conn.note).font(.caption2).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        if let target {
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

    private var coverUIImage: UIImage? { CoverCache.image(at: library.coverURL(work.id)) }

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
        } else {
            SpineCard(work: work, height: coverH).frame(width: coverW)
        }
    }

    private func coverImage(_ img: UIImage) -> some View {
        Image(uiImage: img).resizable().scaledToFill()
            .frame(width: coverW, height: coverH)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.18), lineWidth: 0.5))
            .overlay { if let p = reading.state(work.id)?.progress, p > 0 { ProgressRibbon(progress: p) } }
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
