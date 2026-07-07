import SwiftUI

// A subview tagged with this forces a hard line break before it (used to honor the
// `\n` line breaks in verse, which otherwise flow as if they were spaces).
struct LineBreakKey: LayoutValueKey {
    static let defaultValue: Bool = false
}

// Tags a subview with its token index so the layout can report where it placed it
// (WordFlowText maps touches to words from these frames — far cheaper than giving
// every word its own GeometryReader).
struct TokenIndexKey: LayoutValueKey {
    static let defaultValue: Int = -1
}

// Wrapping layout. Used for the rail's chips and for word-by-word tappable text
// (where horizontal `spacing` is 0 because each word token carries its own trailing
// space, and `lineSpacing` controls the gap between wrapped lines). A subview marked
// with `LineBreakKey` starts a new line — this is how verse keeps its line structure.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat? = nil
    // Called with (tokenIndex, frame-relative-to-layout-origin) for each indexed
    // subview as it is placed. Deliberately NOT in the init: a trailing closure at
    // the many `FlowLayout(spacing:) { chips }` call sites must keep binding to the
    // content builder, so the reporter attaches via .reporting(_:) instead.
    private var onPlace: ((Int, CGRect) -> Void)? = nil

    init(spacing: CGFloat = 6, lineSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    func reporting(_ onPlace: @escaping (Int, CGRect) -> Void) -> FlowLayout {
        var copy = self
        copy.onPlace = onPlace
        return copy
    }

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
            if let onPlace {
                let idx = view[TokenIndexKey.self]
                if idx >= 0 {
                    onPlace(idx, CGRect(x: x, y: y, width: size.width, height: size.height))
                }
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
