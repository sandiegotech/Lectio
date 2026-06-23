import SwiftUI

// Shown once, on first launch — a brief, plain overview of what Lectio is, in The Margin
// design language. Dismissed with "Begin reading"; a persisted flag keeps it from returning.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    var onDone: () -> Void = {}
    private var pal: Palette { Palette.forScheme(colorScheme) }

    var body: some View {
        ZStack {
            pal.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 44)

                    HStack(spacing: 5) {
                        Text("Lectio")
                            .font(.system(size: 36, weight: .semibold, design: .serif))
                            .foregroundColor(pal.ink)
                        Circle().fill(pal.accent).frame(width: 7, height: 7).offset(y: 9)
                    }
                    Text("FROM THE SAN DIEGO INSTITUTE OF TECHNOLOGY")
                        .font(.caption2).tracking(2).foregroundColor(pal.inkSoft.opacity(0.9))
                        .padding(.top, 7)

                    Text("The great books of the world, made to read with ease.")
                        .font(.system(size: 22, design: .serif)).italic()
                        .foregroundColor(pal.ink).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 24)

                    Text("Lectio brings you the classics of East and West in a clear modern edition you can actually read — with the historical translations and the original language always one tap away.")
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(pal.inkSoft).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 18) {
                        feature("book.closed", "Read with ease",
                                "Every work in a fresh, plain-modern-English Lectio edition — read by default.")
                        feature("arrow.left.arrow.right", "Every translation, one tap away",
                                "Switch to a public-domain translation, or read the original language.")
                        feature("sidebar.right", "The margin",
                                "Tap a word to define it; meet the people, places, and ideas beside the text.")
                        feature("point.3.connected.trianglepath.dotted", "Explore the threads",
                                "Start from a famous line and follow it across the traditions, East and West.")
                    }
                    .padding(.top, 28)

                    Spacer(minLength: 34)

                    Button { onDone(); dismiss() } label: {
                        Text("Begin reading")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(pal.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Capsule().fill(pal.accent))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Text("Free, and public-domain first.")
                        .font(.caption).foregroundColor(pal.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func feature(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18)).foregroundColor(pal.accent)
                .frame(width: 26, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundColor(pal.ink)
                Text(text)
                    .font(.footnote).foregroundColor(pal.inkSoft).lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
