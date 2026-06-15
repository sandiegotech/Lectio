import SwiftUI

// "The Margin" design language. Two reading themes (BIBLE.md §4.5): a warm
// "Natural" parchment book and a clean "Modern" reader. A single rubrication-red
// accent for emphasis — never decoration.

enum ReaderMode: String, CaseIterable, Identifiable {
    case natural = "Natural"
    case modern = "Modern"
    var id: String { rawValue }
}

struct Palette {
    var paper: Color
    var ink: Color
    var inkSoft: Color
    var accent: Color
    var gold: Color
    var rule: Color
    var rail: Color

    static let natural = Palette(
        paper: Color(hex: 0xF4EEE1),
        ink: Color(hex: 0x26221A),
        inkSoft: Color(hex: 0x6B6355),
        accent: Color(hex: 0x9E3B2E),
        gold: Color(hex: 0xB98A2E),
        rule: Color(hex: 0x26221A).opacity(0.14),
        rail: Color(hex: 0xEFE7D6)
    )

    static let modern = Palette(
        paper: Color(hex: 0xFBFAF7),
        ink: Color(hex: 0x1E1B16),
        inkSoft: Color(hex: 0x6E6A61),
        accent: Color(hex: 0x9E3B2E),
        gold: Color(hex: 0x9A7320),
        rule: Color.black.opacity(0.08),
        rail: Color(hex: 0xF4F2ED)
    )

    static func of(_ mode: ReaderMode) -> Palette {
        mode == .natural ? .natural : .modern
    }
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// Coloured spine cards for the shelf — a small deterministic set of book-cloth hues.
enum SpineColor {
    static let palette: [Color] = [
        Color(hex: 0x3A4A3F), Color(hex: 0x5A3B34),
        Color(hex: 0x3F3A52), Color(hex: 0x6B5326),
        Color(hex: 0x4A4036), Color(hex: 0x2F4858),
    ]
    static func color(for id: String) -> Color {
        // Stable across launches (Swift's hashValue is per-process randomized).
        let sum = id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[sum % palette.count]
    }
}
