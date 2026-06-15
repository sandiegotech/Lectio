import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var library: Library
    @EnvironmentObject var theme: AppTheme
    @State private var path: [Work] = []
    private var pal: Palette { theme.palette }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    HStack {
                        Spacer()
                        appearanceButton
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    masthead
                    ForEach(library.collections) { collection in
                        shelf(collection)
                    }
                    instituteCredit
                }
                .padding(.vertical, 6)
            }
            .background(pal.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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

    private var appearanceButton: some View {
        Button { withAnimation(.easeInOut(duration: 0.25)) { theme.toggle() } } label: {
            Image(systemName: theme.mode == .dark ? "sun.max" : "moon")
                .font(.system(size: 15))
                .foregroundColor(pal.inkSoft)
                .padding(8)
                .background(Circle().fill(pal.rail))
                .overlay(Circle().stroke(pal.rule))
        }
        .buttonStyle(.plain)
    }

    // MARK: masthead

    private var masthead: some View {
        VStack(spacing: 8) {
            Text("Lectio")
                .font(.system(size: 44, weight: .semibold, design: .serif))
                .foregroundColor(pal.ink)
            HStack(spacing: 10) {
                Rectangle().fill(pal.accent.opacity(0.65)).frame(width: 30, height: 1)
                Image(systemName: "diamond.fill").font(.system(size: 6)).foregroundColor(pal.accent)
                Rectangle().fill(pal.accent.opacity(0.65)).frame(width: 30, height: 1)
            }
            Text("The great books, made to read")
                .font(.system(.subheadline, design: .serif)).italic()
                .foregroundColor(pal.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 26)
        .padding(.bottom, 6)
    }

    // MARK: a shelf (one collection, books standing on a ledge)

    private func shelf(_ collection: BookCollection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.system(.title2, design: .serif).weight(.medium))
                    .foregroundColor(pal.ink)
                Text(collection.blurb)
                    .font(.subheadline)
                    .foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 18) {
                    ForEach(library.works(in: collection)) { work in
                        NavigationLink(value: work) {
                            SpineCard(work: work)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 150)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 10)
            }

            // shelf ledge the books rest on
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(hex: 0x9A8763).opacity(0.55), Color(hex: 0x6E5C3E).opacity(0.55)],
                    startPoint: .top, endPoint: .bottom))
                .frame(height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .shadow(color: .black.opacity(0.16), radius: 4, y: 3)
                .padding(.horizontal, 14)
        }
    }

    // MARK: institute credit

    private var instituteCredit: some View {
        VStack(spacing: 8) {
            Rectangle().fill(pal.rule).frame(width: 40, height: 1)
            Text("SAN DIEGO INSTITUTE OF TECHNOLOGY")
                .font(.system(size: 10.5, weight: .medium))
                .tracking(1.8)
                .foregroundColor(pal.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 22)
        .padding(.bottom, 30)
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
