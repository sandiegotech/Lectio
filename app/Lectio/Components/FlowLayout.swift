import SwiftUI

// A subview tagged with this forces a hard line break before it (used to honor the
// `\n` line breaks in verse, which otherwise flow as if they were spaces).
struct LineBreakKey: LayoutValueKey {
    static let defaultValue: Bool = false
}

// Wrapping layout. Used for the rail's chips and for word-by-word tappable text
// (where horizontal `spacing` is 0 because each word token carries its own trailing
// space, and `lineSpacing` controls the gap between wrapped lines). A subview marked
// with `LineBreakKey` starts a new line — this is how verse keeps its line structure.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat? = nil

    private var vGap: CGFloat { lineSpacing ?? spacing }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            if view[LineBreakKey.self] {
                y += rowHeight + vGap; x = 0; rowHeight = 0
                continue
            }
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + vGap
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = maxWidth == .infinity ? x : maxWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            if view[LineBreakKey.self] {
                y += rowHeight + vGap; x = 0; rowHeight = 0
                continue
            }
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.width, x > 0 {
                x = 0
                y += rowHeight + vGap
                rowHeight = 0
            }
            view.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                       proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
