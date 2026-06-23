import SwiftUI

// The Explore / "famous lines" feed — a welcoming doorway into the library rather than a
// wall of books: a signature line from a work, what it's about, and the cross-tradition
// threads it pulls toward other books. Embeds in LibraryView's scroll (no scroll of its own).
struct ExploreFeed: View {
    @EnvironmentObject var library: Library
    @Environment(\.colorScheme) private var colorScheme
    private var pal: Palette { Palette.forScheme(colorScheme) }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("TODAY'S EXPLORE")
                    .font(.caption2.weight(.semibold)).tracking(2)
                    .foregroundColor(pal.accent)
                Text(todayLabel)
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundColor(pal.ink)
                Text("A famous line and the threads it pulls across the traditions. A new order each day — today's stays put, so you can read through them all.")
                    .font(.system(size: 14, design: .serif)).italic()
                    .foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 1)
            }
            .padding(.horizontal, 26).padding(.top, 2)
            ForEach(dailyOrder) { card($0) }
        }
        .padding(.bottom, 18)
    }

    // One stable page per day. The records are ordered by a date seed, so the order holds all
    // day (browse them all without it reshuffling under you) and turns over the next day —
    // fresh, never stale, but never moving while you read. No per-visit shuffle.
    private var dailyOrder: [ExploreRecord] {
        let seed = daySeed()
        return library.explore.sorted { dayHash($0.title, seed) < dayHash($1.title, seed) }
    }
    private func daySeed() -> Int {
        // Whole days since 1970 at the local day boundary — a stable integer that ticks once a day.
        let midnight = Calendar.current.startOfDay(for: Date())
        return Int(midnight.timeIntervalSince1970 / 86_400)
    }
    private func dayHash(_ s: String, _ seed: Int) -> UInt64 {   // deterministic FNV-1a (Hasher isn't stable across launches)
        var h: UInt64 = 14695981039346656037
        for b in "\(seed):\(s)".utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return h
    }
    private var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    @ViewBuilder
    private func card(_ rec: ExploreRecord) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("\u{201C}\(rec.quote)\u{201D}")
                .font(.system(size: 21, design: .serif)).lineSpacing(4)
                .foregroundColor(pal.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let book = library.bookOverview(title: rec.title) {
                NavigationLink(value: book) {
                    HStack(spacing: 5) {
                        Text("— \(rec.title)\(rec.author.isEmpty ? "" : ", \(rec.author)")")
                            .font(.system(.subheadline, design: .serif).weight(.medium))
                            .foregroundColor(pal.accent)
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                            .foregroundColor(pal.accent)
                    }
                }
                .buttonStyle(.plain)
            }
            Text(rec.source).font(.caption2).foregroundColor(pal.inkSoft.opacity(0.8))
            Text(rec.essence).font(.footnote).foregroundColor(pal.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if rec.original?.isEmpty == false || rec.translationNote?.isEmpty == false {
                Rectangle().fill(pal.rule).frame(height: 1).padding(.vertical, 3)
                Text("ON THE TEXT").font(.caption2).tracking(2).foregroundColor(pal.inkSoft)
                if let o = rec.original, !o.isEmpty { onTextRow("text.book.closed", o) }
                if let tn = rec.translationNote, !tn.isEmpty { onTextRow("quote.bubble", tn) }
            }

            if !rec.connections.isEmpty {
                Rectangle().fill(pal.rule).frame(height: 1).padding(.vertical, 3)
                Text("THREADS").font(.caption2).tracking(2).foregroundColor(pal.inkSoft)
                ForEach(Array(rec.connections.enumerated()), id: \.offset) { _, conn in
                    connectionRow(conn)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(pal.rail))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(pal.rule))
        .padding(.horizontal, 22)
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
    private func connectionRow(_ conn: ExploreRecord.Link) -> some View {
        let row = HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon(conn.type)).font(.caption2)
                .foregroundColor(pal.accent).padding(.top, 2).frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(conn.to).font(.subheadline.weight(.medium)).foregroundColor(pal.accent)
                Text(conn.note).font(.caption2).foregroundColor(pal.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        if let target = library.bookOverview(title: conn.to) {
            NavigationLink(value: target) { row }.buttonStyle(.plain)
        } else {
            row
        }
    }

    private func icon(_ type: String) -> String {
        switch type {
        case "influences": return "arrow.right"
        case "responds-to": return "arrowshape.turn.up.left"
        case "contrasts": return "arrow.left.and.right"
        case "parallel": return "equal"
        default: return "link"
        }
    }
}
