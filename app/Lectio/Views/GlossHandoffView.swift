import SwiftUI

// Receives the inbound `lectio://define?term=…` handoff from the sibling app, Gloss.
// A word studied in Gloss opens here in the classics where it lives: if it's a curated
// glossary entry or a shared concept, we show its in-corpus meaning and where it recurs;
// otherwise a graceful "not in the corpus yet." (BIBLE §8: one shared vocabulary layer.)
struct GlossHandoffView: View {
    let term: String
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    private var pal: Palette { Palette.forScheme(scheme) }
    private var resolved: Library.CorpusGloss? { library.lookupAnywhere(term: term) }

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
                    } else {
                        Text("“\(term)” isn’t a curated entry in Lectio’s classics yet. Browse the library to read the works where words like it live.")
                            .font(.system(.body, design: .serif))
                            .foregroundColor(pal.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
// presents the handoff sheet. Kept as a modifier so LectioApp's scene stays tidy.
struct GlossInboundModifier: ViewModifier {
    @State private var handoffTerm: String?

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                guard url.scheme == "lectio", url.host == "define" else { return }
                let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "term" || $0.name == "q" })?
                    .value?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let value, !value.isEmpty { handoffTerm = value }
            }
            .sheet(item: Binding(
                get: { handoffTerm.map(HandoffID.init) },
                set: { handoffTerm = $0?.term }
            )) { item in
                GlossHandoffView(term: item.term)
            }
    }

    private struct HandoffID: Identifiable { let term: String; var id: String { term } }
}

extension View {
    func glossInbound() -> some View { modifier(GlossInboundModifier()) }
}
