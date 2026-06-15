import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var library: Library
    @State private var path: [Work] = []
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

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

                            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
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
            .navigationTitle("Codex")
            .navigationDestination(for: Work.self) { work in
                ReaderView(work: work)
            }
        }
        .onAppear {
            // Debug hook: CODEX_OPEN_WORK=<workId> opens straight into the reader.
            if let wid = ProcessInfo.processInfo.environment["CODEX_OPEN_WORK"],
               let work = library.works.first(where: { $0.id == wid }) {
                path = [work]
            }
        }
    }
}

struct SpineCard: View {
    let work: Work

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(work.author.uppercased())
                .font(.caption2)
                .tracking(1)
                .opacity(0.75)
            Spacer(minLength: 8)
            Text(work.title)
                .font(.system(.title3, design: .serif))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(height: 156, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SpineColor.color(for: work.id))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
