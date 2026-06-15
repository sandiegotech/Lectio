import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var library: Library
    @State private var path: [Work] = []
    private let columns = [GridItem(.adaptive(minimum: 158), spacing: 22)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(library.collections) { collection in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(collection.title)
                                .font(.system(.title2, design: .serif).weight(.medium))
                                .foregroundStyle(Palette.natural.ink)
                            Text(collection.blurb)
                                .font(.subheadline)
                                .foregroundStyle(Palette.natural.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)

                            LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                                ForEach(library.works(in: collection)) { work in
                                    NavigationLink(value: work) {
                                        SpineCard(work: work)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.natural.paper.ignoresSafeArea())
            .navigationTitle("Lectio")
            .navigationDestination(for: Work.self) { work in
                ReaderView(work: work)
            }
        }
        .onAppear {
            // Debug hook: LECTIO_OPEN_WORK=<workId> opens straight into the reader.
            if let wid = ProcessInfo.processInfo.environment["LECTIO_OPEN_WORK"],
               let work = library.works.first(where: { $0.id == wid }) {
                path = [work]
            }
        }
    }
}

// A fine clothbound cover: dyed book-cloth with depth, a gilt double-rule frame,
// a faint classical emblem, small-caps author, serif title, and a laurel ornament.
struct SpineCard: View {
    let work: Work

    private let gilt = Color(hex: 0xC6A867)
    private let cream = Color(hex: 0xEFE6D2)

    var body: some View {
        let cloth = SpineColor.color(for: work.id)
        ZStack {
            // Cloth base with a subtle sheen + vignette for depth.
            cloth
            LinearGradient(
                colors: [Color.white.opacity(0.08), .clear, Color.black.opacity(0.24)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Spine fold along the left edge.
            HStack(spacing: 0) {
                Color.black.opacity(0.20).frame(width: 6)
                Color.white.opacity(0.10).frame(width: 1)
                Spacer()
            }
            // Faint embossed emblem behind the title.
            Image(systemName: emblem)
                .font(.system(size: 88, weight: .light))
                .foregroundColor(gilt.opacity(0.12))
                .offset(y: 4)
            // Gilt double-rule frame.
            RoundedRectangle(cornerRadius: 4).inset(by: 9)
                .stroke(gilt.opacity(0.55), lineWidth: 1)
            RoundedRectangle(cornerRadius: 2).inset(by: 13)
                .stroke(gilt.opacity(0.30), lineWidth: 0.5)

            VStack(spacing: 8) {
                Text(work.author.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(2.5)
                    .foregroundColor(gilt)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Rectangle().fill(gilt.opacity(0.7)).frame(width: 24, height: 1)
                Spacer(minLength: 2)
                Text(work.title)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 2)
                HStack(spacing: 3) {
                    Image(systemName: "laurel.leading")
                    Circle().fill(gilt).frame(width: 3, height: 3)
                    Image(systemName: "laurel.trailing")
                }
                .font(.system(size: 13))
                .foregroundColor(gilt.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
        }
        .frame(height: 234)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
    }

    private var emblem: String {
        switch work.type {
        case "philosophy": return "building.columns"
        case "epic_poem": return "shield.lefthalf.filled"
        default: return "book.closed"
        }
    }
}
