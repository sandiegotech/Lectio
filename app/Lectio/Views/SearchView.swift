import SwiftUI

// Search the library's works by title or author. Choosing one hands it back to the
// library (`onOpen`), which closes this sheet and opens the book on its own stack.
struct SearchView: View {
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    private let seed: String
    private let onOpen: (Work) -> Void
    private var pal: Palette { Palette.forScheme(colorScheme) }

    init(initialQuery: String = "", onOpen: @escaping (Work) -> Void) {
        seed = initialQuery
        self.onOpen = onOpen
    }

    private var results: [Work] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return library.works
            .filter { $0.title.lowercased().contains(q) || $0.author.lowercased().contains(q) }
            .sorted { $0.title < $1.title }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                Divider().overlay(pal.rule)
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    hint
                } else if results.isEmpty {
                    empty
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(results) { row($0) }
                        }
                        .padding(.vertical, 6)
                    }
                }
                Spacer(minLength: 0)
            }
            .background(pal.paper.ignoresSafeArea())
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if query.isEmpty {
                    if !seed.isEmpty { query = seed }
                    #if DEBUG
                    if query.isEmpty, let q = ProcessInfo.processInfo.environment["LECTIO_DEBUG_SEARCH"] { query = q }
                    #endif
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(pal.accent)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(pal.inkSoft)
            TextField("Search the library", text: $query)
                .font(.system(.body, design: .serif))
                .foregroundColor(pal.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(pal.inkSoft.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
    }

    private func row(_ w: Work) -> some View {
        Button { onOpen(w) } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(w.title).font(.system(.subheadline, design: .serif).weight(.medium))
                            .foregroundColor(pal.ink)
                        Text(w.composed).font(.caption2).foregroundColor(pal.accent.opacity(0.85))
                    }
                    Text(w.author).font(.caption).foregroundColor(pal.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                    .foregroundColor(pal.inkSoft)
            }
            .padding(.horizontal, 18).padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var hint: some View {
        Text("Search the library by title or author.")
            .font(.footnote).foregroundColor(pal.inkSoft)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 40).padding(.top, 40)
    }

    private var empty: some View {
        Text("No works match “\(query)”.")
            .font(.footnote).foregroundColor(pal.inkSoft)
            .padding(.top, 40)
    }
}
