import SwiftUI

// Search the whole corpus — every work, readable or not. Ingested works open in the
// reader; shells show as coming soon; in-copyright works appear greyed with the year
// they enter the public domain. Reachable even when locked works are hidden on the shelves.
struct SearchView: View {
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    private let seed: String
    private var pal: Palette { Palette.forScheme(colorScheme) }

    init(initialQuery: String = "") { seed = initialQuery }

    private struct Hit: Identifiable {
        let id: String
        let title: String
        let author: String
        let era: String
        let note: String
        let work: Work?
        let opens: Int?
        var isLocked: Bool { opens != nil }
    }

    // Every work once: real works first, then unique shells across all collections.
    private var corpus: [Hit] {
        var out: [Hit] = []
        var seen = Set<String>()
        func key(_ t: String, _ a: String) -> String { (t + "|" + a).lowercased() }
        for w in library.works {
            seen.insert(key(w.title, w.author))
            out.append(Hit(id: "w:" + w.id, title: w.title, author: w.author,
                           era: w.composed, note: w.blurb, work: w, opens: nil))
        }
        for c in library.collections {
            for p in c.planned ?? [] {
                let k = key(p.title, p.author ?? "")
                if seen.contains(k) { continue }
                seen.insert(k)
                out.append(Hit(id: "p:" + k, title: p.title, author: p.author ?? "",
                               era: p.era ?? "", note: p.note ?? "", work: nil,
                               opens: p.isLocked ? p.opens : nil))
            }
        }
        return out
    }

    private var results: [Hit] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return corpus
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
                            ForEach(results) { hit in row(hit) }
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
                    else if let q = ProcessInfo.processInfo.environment["LECTIO_DEBUG_SEARCH"] { query = q }
                }
            }
            .navigationDestination(for: Work.self) { ReaderView(work: $0) }
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

    @ViewBuilder
    private func row(_ hit: Hit) -> some View {
        let content = HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(hit.title).font(.system(.subheadline, design: .serif).weight(.medium))
                        .foregroundColor(pal.ink)
                    if !hit.era.isEmpty {
                        Text(hit.era).font(.caption2).foregroundColor(pal.accent.opacity(0.85))
                    }
                }
                if !hit.author.isEmpty {
                    Text(hit.author).font(.caption).foregroundColor(pal.inkSoft)
                }
                statusLine(hit)
            }
            Spacer(minLength: 0)
            if hit.work != nil {
                Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                    .foregroundColor(pal.inkSoft)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 11)
        .opacity(hit.isLocked ? 0.55 : 1)

        if let w = hit.work {
            NavigationLink(value: w) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    @ViewBuilder
    private func statusLine(_ hit: Hit) -> some View {
        if hit.work != nil {
            Label("Read now", systemImage: "book")
                .font(.caption2.weight(.medium)).foregroundColor(pal.accent)
        } else if let y = hit.opens {
            Label("Enters the public domain in \(String(y))", systemImage: "lock.fill")
                .font(.caption2).foregroundColor(pal.inkSoft)
        } else {
            Label("Coming soon", systemImage: "hourglass")
                .font(.caption2).foregroundColor(pal.inkSoft)
        }
    }

    private var hint: some View {
        Text("Search every book in the library by title or author — including works still under copyright.")
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
