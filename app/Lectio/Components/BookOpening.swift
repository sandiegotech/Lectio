import SwiftUI

// What the reader lands on once the book has opened.
enum OpenRoute {
    case work(Work)            // the reader, at the saved place
    case reader(ReaderRoute)   // the reader, at a given place or edition
}

// Opening a book: the tapped cover lifts from its place, comes to the centre, and swings
// open about its spine onto a title page; the reader fades in behind it. Views call
// `open(_:from:)` with the cover's frame in global space; LibraryView owns the overlay
// and the navigation push (`push`). DEBUG hooks push directly and skip all of this.
final class BookOpener: ObservableObject {
    struct Opening: Equatable {
        let work: Work
        let from: CGRect
        let id = UUID()
    }
    @Published private(set) var opening: Opening?
    private var route: OpenRoute?
    var push: (OpenRoute) -> Void = { _ in }

    func open(_ work: Work, from frame: CGRect, to route: OpenRoute? = nil) {
        guard opening == nil else { return }
        self.route = route ?? .work(work)
        opening = Opening(work: work, from: frame)
    }

    // Push the reader (once), without the stack's own slide: the overlay hides the swap.
    func pushNow() {
        guard let r = route else { return }
        route = nil
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { push(r) }
    }

    func finish() {
        pushNow()
        opening = nil
    }

    // Which edition the reader will open, so it can decode while the cover moves.
    var editionHint: String? {
        if case .reader(let r)? = route, case .edition(let id) = r.target { return id }
        return nil
    }
}

// Where a cover sits on screen, kept by reference: written on every layout pass, read
// only when tapped, so it never re-renders the view that owns it.
final class CoverFrame {
    var frame: CGRect = .zero
}

struct BookOpeningOverlay: View {
    @EnvironmentObject var opener: BookOpener
    @EnvironmentObject var library: Library
    @EnvironmentObject var reading: ReadingState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    // 0 at the source · 1 centred · 2 open on the title page · 3 page fills the screen ·
    // 4 fading out onto the reader
    @State private var phase = 0
    private var pal: Palette { Palette.forScheme(colorScheme) }

    var body: some View {
        GeometryReader { geo in
            if let o = opener.opening {
                let full = CGRect(origin: .zero, size: geo.size)
                let book = phase == 0 ? o.from : centred(in: geo.size)
                let page = phase >= 3 ? full : book
                ZStack(alignment: .topLeading) {
                    pal.paper.opacity(phase >= 1 ? 1 : 0)
                    if !reduceMotion {
                        titlePage(o.work)
                            .frame(width: page.width, height: page.height)
                            .position(x: page.midX, y: page.midY)
                        cover(o.work)
                            .frame(width: book.width, height: book.height)
                            .shadow(color: .black.opacity(phase >= 1 ? 0.3 : 0.15),
                                    radius: phase >= 1 ? 22 : 8, y: phase >= 1 ? 12 : 4)
                            .rotation3DEffect(.degrees(phase >= 2 ? -90 : 0), axis: (x: 0, y: 1, z: 0),
                                              anchor: .leading, perspective: 0.45)
                            .opacity(phase >= 3 ? 0 : 1)
                            .position(x: book.midX, y: book.midY)
                    }
                }
                .opacity(phase == 4 ? 0 : 1)
                .contentShape(Rectangle())
                .onTapGesture { complete() }   // interruptible: a tap finishes it
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(opener.opening != nil)
        .task(id: opener.opening?.id) { await run() }
    }

    private func run() async {
        guard let o = opener.opening else { phase = 0; return }
        phase = 0
        // Decode the edition while the cover moves (Library.edition is thread-safe).
        let eid = opener.editionHint ?? reading.state(o.work.id)?.editionId ?? o.work.defaultEditionId
        let library = library
        DispatchQueue.global(qos: .userInitiated).async { _ = library.edition(eid) }

        // The reader is pushed only once the page covers the screen: building it takes the
        // main thread for a moment, and a pause on a blank page reads as the page turning,
        // where a pause mid-swing would read as a stutter.
        let steps: [(Int, Animation, Int)] = reduceMotion
            ? [(3, .easeInOut(duration: 0.2), 200), (4, .easeOut(duration: 0.25), 250)]
            : [(1, .easeInOut(duration: 0.32), 320), (2, .easeInOut(duration: 0.34), 340),
               (3, .easeInOut(duration: 0.18), 180), (4, .easeOut(duration: 0.22), 220)]
        for (target, animation, ms) in steps {
            if target == 4 {
                opener.pushNow()
                // Let the reader lay out and restore its place first: each sleep resumes only
                // once the main thread is free again, so the fade starts on a ready page.
                for _ in 0..<3 { try? await Task.sleep(for: .milliseconds(40)) }
            }
            withAnimation(animation) { phase = target }
            try? await Task.sleep(for: .milliseconds(ms))
            if Task.isCancelled || opener.opening?.id != o.id { return }
        }
        opener.finish()
    }

    private func complete() {
        opener.finish()
    }

    // The book at rest in the middle of the screen, in the cover's proportions.
    private func centred(in size: CGSize) -> CGRect {
        let aspect: CGFloat = 908.0 / 1403.0
        let h = min(size.height * 0.56, size.width * 0.6 / aspect)
        let w = h * aspect
        return CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h)
    }

    @ViewBuilder
    private func cover(_ work: Work) -> some View {
        Group {
            if let img = CoverCache.image(at: library.coverURL(work.id)) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                SpineCard(work: work, height: nil)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // The page under the cover: a plain title page on parchment.
    private func titlePage(_ work: Work) -> some View {
        VStack(spacing: 10) {
            Text(work.author.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .serif)).tracking(2)
                .foregroundColor(pal.inkSoft)
            Text(work.title)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(pal.ink)
                .multilineTextAlignment(.center)
            Image(systemName: "diamond.fill").font(.system(size: 5)).foregroundColor(pal.accent)
        }
        .padding(18)
        .opacity(phase == 2 ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: phase >= 3 ? 0 : 4).fill(pal.paper))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(pal.rule).opacity(phase >= 3 ? 0 : 1))
        .shadow(color: .black.opacity(phase >= 3 ? 0 : 0.12), radius: 10, y: 4)
    }
}

// Progress as a bookmark: a slim red ribbon hanging from the top of the cover, as long
// as the reader is far through the book. Finished (≥ 98%) runs the full height.
struct ProgressRibbon: View {
    let progress: Double
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { g in
            let p = progress >= 0.98 ? 1 : min(max(progress, 0.06), 0.97)
            let w = max(5, g.size.width * 0.065)
            RibbonShape()
                .fill(Palette.forScheme(colorScheme).accent)
                .frame(width: w, height: g.size.height * p)
                .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0.5, y: 1)
                .position(x: g.size.width * 0.8, y: g.size.height * p / 2)
        }
        .allowsHitTesting(false)
        .accessibilityLabel("\(percentLabel(progress)) read")
    }
}

// A ribbon with a swallowtail notch at its end.
struct RibbonShape: Shape {
    func path(in r: CGRect) -> Path {
        let notch = min(r.width * 0.7, r.height * 0.3)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - notch))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
