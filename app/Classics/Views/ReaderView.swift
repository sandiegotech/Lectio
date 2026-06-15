import SwiftUI

struct ReaderView: View {
    let work: Work
    @EnvironmentObject var library: Library
    @EnvironmentObject var dictionary: WordDictionary
    @EnvironmentObject var saved: SavedStore
    @Environment(\.dismiss) private var dismiss

    @State private var explore = true
    @State private var showContents = false
    @State private var selectedTerm: String?
    @State private var selectedDef: String?
    @State private var currentSectionId: String?
    @State private var scrollTarget: String?
    @State private var showWordSheet = false

    private let pal = Palette.natural
    private var edition: Edition? { library.edition(for: work) }

    private var currentSection: Section? {
        guard let ed = edition else { return nil }
        return ed.sections.first { $0.id == currentSectionId } ?? ed.sections.first
    }

    private var progress: Double {
        guard let ed = edition, !ed.sections.isEmpty, let cur = currentSection,
              let idx = ed.sections.firstIndex(where: { $0.id == cur.id }) else { return 0 }
        return Double(idx + 1) / Double(ed.sections.count)
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 680
            VStack(spacing: 0) {
                header
                Divider().overlay(pal.rule)

                if let ed = edition {
                    HStack(alignment: .top, spacing: 0) {
                        readingColumn(ed, wide: wide)
                        if explore && wide {
                            MarginRail(
                                work: work, section: currentSection, edition: ed, pal: pal,
                                progress: progress,
                                selectedTerm: selectedTerm, selectedDef: selectedDef,
                                onClearSelection: clearSelection
                            )
                            .frame(width: max(240, geo.size.width * 0.30))
                            .background(pal.rail)
                        }
                    }
                } else {
                    Spacer()
                    Text("No edition available.").foregroundColor(pal.inkSoft)
                    Spacer()
                }

                Divider().overlay(pal.rule)
                footer
            }
            .background(pal.paper)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showContents) { contentsSheet }
        .sheet(isPresented: $showWordSheet) {
            if let term = selectedTerm {
                WordDetail(term: term, definition: selectedDef, workTitle: work.title, pal: pal)
                    .presentationDetents([.medium])
            }
        }
        .onAppear {
            if currentSectionId == nil { currentSectionId = edition?.sections.first?.id }
            // Debug hook: CLASSICS_DEBUG_SELECT=<word> preselects a word (for screenshots).
            if let dbg = ProcessInfo.processInfo.environment["CLASSICS_DEBUG_SELECT"], !dbg.isEmpty {
                let w = WordDictionary.normalize(dbg)
                selectedTerm = w
                selectedDef = dictionary.define(w)
            }
        }
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 14) {
            iconButton("chevron.left") { dismiss() }
            iconButton("list.bullet") { showContents = true }
            VStack(alignment: .leading, spacing: 1) {
                Text(work.title).font(.subheadline.weight(.medium)).foregroundColor(pal.ink)
                Text(byline).font(.caption2).foregroundColor(pal.inkSoft)
            }
            Spacer()
            explorePill
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(pal.paper)
    }

    private var byline: String {
        guard let e = edition else { return work.author }
        var parts = [work.author]
        if let t = e.translator { parts.append(t) }
        if let y = e.publishedYear { parts.append(String(y)) }
        return parts.joined(separator: " · ")
    }

    private func iconButton(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.body.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundColor(pal.inkSoft)
    }

    private var explorePill: some View {
        Button { explore.toggle() } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles").font(.caption2)
                Text("Explore").font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(explore ? pal.accent : pal.paper)
            .foregroundColor(explore ? Color.white : pal.ink)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(pal.rule))
        }
        .buttonStyle(.plain)
    }

    // MARK: reading column (whole book, continuous scroll)

    private enum Row: Identifiable {
        case header(Section)
        case segment(Segment)
        var id: String {
            switch self {
            case .header(let s): return "h:" + s.id
            case .segment(let seg): return seg.id
            }
        }
    }

    private func rows(_ ed: Edition) -> [Row] {
        var result: [Row] = []
        for section in ed.sections {
            result.append(.header(section))
            for segment in section.segments { result.append(.segment(segment)) }
        }
        return result
    }

    private func readingColumn(_ ed: Edition, wide: Bool) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(rows(ed)) { row in
                        switch row {
                        case .header(let section):
                            sectionHeader(section)
                                .id(section.id)
                                .onAppear { currentSectionId = section.id }
                        case .segment(let segment):
                            WordFlowText(text: segment.text, pal: pal,
                                         highlight: selectedTerm,
                                         onSelect: { selectWord($0, wide: wide) })
                        }
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                withAnimation { proxy.scrollTo(target, anchor: .top) }
                currentSectionId = target
            }
        }
    }

    private func sectionHeader(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.label.uppercased())
                .font(.caption).tracking(2).foregroundColor(pal.accent)
            if let title = section.title {
                Text(title).font(.system(.title3, design: .serif)).italic().foregroundColor(pal.ink)
            }
        }
        .padding(.top, 10)
    }

    // MARK: contents

    private var contentsSheet: some View {
        NavigationStack {
            List(edition?.sections ?? []) { section in
                Button {
                    scrollTarget = section.id
                    showContents = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.label).font(.body)
                            if let title = section.title {
                                Text(title).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if section.id == currentSectionId {
                            Image(systemName: "book").foregroundColor(pal.accent)
                        }
                    }
                }
                .tint(pal.ink)
            }
            .navigationTitle("Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showContents = false }
                }
            }
        }
    }

    // MARK: footer

    private var footer: some View {
        HStack {
            if let p = edition?.provenance {
                Label("Public domain · \(provenanceSource(p))", systemImage: "checkmark.shield")
                    .font(.caption2).foregroundColor(pal.inkSoft)
            }
            Spacer()
            if let section = currentSection {
                Text("\(section.label) · \(section.segments.count) segments")
                    .font(.caption2).foregroundColor(pal.inkSoft)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(pal.paper)
    }

    // MARK: actions

    private func selectWord(_ word: String, wide: Bool) {
        selectedTerm = word
        selectedDef = dictionary.define(word) ?? passageGloss(word)
        if wide { explore = true } else { showWordSheet = true }
    }

    private func clearSelection() {
        selectedTerm = nil
        selectedDef = nil
    }

    private func passageGloss(_ word: String) -> String? {
        guard let section = currentSection,
              let passage = library.passage(workId: work.id, sectionId: section.id) else { return nil }
        return passage.define?.first { WordDictionary.normalize($0.term) == word }?.gloss
    }

    private func provenanceSource(_ p: Provenance) -> String {
        switch p.source {
        case "gutenberg": return "Project Gutenberg" + (p.sourceId.map { " #\($0)" } ?? "")
        case "standard_ebooks": return "Standard Ebooks"
        case "wikisource": return "Wikisource"
        default: return p.source.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
