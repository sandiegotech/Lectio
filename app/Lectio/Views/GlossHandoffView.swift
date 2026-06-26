import SwiftUI

// Receives the inbound `lectio://define?term=…` handoff from the sibling app, Gloss.
// A word studied in Gloss opens here in the classics where it lives: if it's a curated
// glossary entry or a shared concept, we show its in-corpus meaning and where it recurs.
// When Gloss hands over its own explanation (`def`), we surface it and let the reader
// keep it in their Lectio vocabulary. (BIBLE §8: one shared vocabulary layer.)
struct GlossHandoffView: View {
    let term: String
    var glossDefinition: String? = nil
    @EnvironmentObject var library: Library
    @EnvironmentObject var saved: SavedStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    private var pal: Palette { Palette.forScheme(scheme) }
    private var resolved: Library.CorpusGloss? { library.lookupAnywhere(term: term) }
    // What we store if the reader saves the word: prefer Gloss's explanation, fall back
    // to Lectio's own corpus gloss.
    private var saveableDefinition: String { glossDefinition ?? resolved?.gloss ?? "" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if let r = resolved {
                        Text(r.gloss)
                            .font(.system(.body, design: .serif))
                            .foregroundColor(pal.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let c = r.concept { conceptBlock(c) }
                        if !r.appearsIn.isEmpty { appearsIn(r.appearsIn) }
                    } else if glossDefinition == nil {
                        Text("“\(term)” isn’t a curated entry in Lectio’s classics yet. Browse the library to read the works where words like it live.")
                            .font(.system(.body, design: .serif))
                            .foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let def = glossDefinition, !def.isEmpty { glossBlock(def) }
                    saveButton
                    Spacer(minLength: 8)
                    fromGloss
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(pal.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.tint(pal.accent)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(resolved?.term ?? term)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundColor(pal.accent)
            if let kind = resolved?.kind, !kind.isEmpty { kindChip(kind) }
        }
    }

    // Gloss's own explanation, carried over the handoff. Set off from Lectio's corpus
    // gloss with a quiet label so it's clear which app it came from.
    private func glossBlock(_ def: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if resolved != nil { Divider().overlay(pal.rule).padding(.vertical, 2) }
            Text("FROM GLOSS").font(.system(size: 10, weight: .semibold)).tracking(0.8)
                .foregroundColor(pal.inkSoft)
            Text(def)
                .font(.system(.callout, design: .serif))
                .foregroundColor(pal.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // Keep the word (and its definition) in Lectio's personal vocabulary — the same
    // saved-words layer the reader builds while reading.
    @ViewBuilder
    private var saveButton: some View {
        let isSaved = saved.isSaved(term)
        Button {
            saved.toggle(SavedWord(term: resolved?.term ?? term, definition: saveableDefinition,
                                   workTitle: resolved?.appearsIn.first?.title, workId: nil))
        } label: {
            Label(isSaved ? "Saved to your words" : "Save to my words",
                  systemImage: isSaved ? "bookmark.fill" : "bookmark")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSaved ? pal.accent : pal.paper)
                .foregroundColor(isSaved ? .white : pal.accent)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(pal.rule))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func conceptBlock(_ c: Concept) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let o = c.original {
                HStack(spacing: 6) {
                    Text(o.lemma).font(.system(.body, design: .serif)).foregroundColor(pal.ink)
                    if let t = o.translit { Text(t).font(.callout.italic()).foregroundColor(pal.inkSoft) }
                    if let lit = o.literal { Text("“\(lit)”").font(.callout).foregroundColor(pal.inkSoft) }
                }
            }
            if let sense = c.senseHistory {
                Text(sense).font(.callout).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 2)
    }

    private func appearsIn(_ works: [(id: String, title: String)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider().overlay(pal.rule).padding(.vertical, 4)
            (Text("Appears in  ").foregroundColor(pal.inkSoft)
             + Text(works.map(\.title).joined(separator: ", ")).foregroundColor(pal.accent))
                .font(.system(.subheadline, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fromGloss: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle.magnifyingglass").font(.caption2)
            Text("from Gloss").font(.system(size: 11, weight: .regular)).tracking(0.3)
        }
        .foregroundColor(pal.inkSoft.opacity(0.7))
    }

    private func kindChip(_ kind: String) -> some View {
        Text(kind.uppercased())
            .font(.system(size: 10, weight: .semibold)).tracking(0.6)
            .foregroundColor(pal.inkSoft)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().stroke(pal.rule))
    }
}

// Attaches the inbound-URL plumbing to the app's root: catches lectio:// links and
// presents the handoff sheet. The env objects are injected explicitly here — a sheet
// does NOT inherit `.environmentObject` from its presenter, so reading them inside the
// sheet without re-injection crashes ("No ObservableObject of type Library found").
struct GlossInboundModifier: ViewModifier {
    let library: Library
    let saved: SavedStore
    @State private var handoff: Handoff?

    struct Handoff: Identifiable { let id = UUID(); let term: String; let def: String? }

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                guard url.scheme == "lectio", url.host == "define" else { return }
                let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                func q(_ name: String) -> String? {
                    comps?.queryItems?.first { $0.name == name }?.value?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                guard let term = (q("term") ?? q("q")), !term.isEmpty else { return }
                handoff = Handoff(term: term, def: q("def"))
            }
            .sheet(item: $handoff) { h in
                GlossHandoffView(term: h.term, glossDefinition: (h.def?.isEmpty == false) ? h.def : nil)
                    .environmentObject(library)
                    .environmentObject(saved)
            }
    }
}

extension View {
    func glossInbound(library: Library, saved: SavedStore) -> some View {
        modifier(GlossInboundModifier(library: library, saved: saved))
    }
}
