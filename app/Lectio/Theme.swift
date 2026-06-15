import SwiftUI

// "The Margin" design language: a warm parchment theme by day and a warm dark theme
// by night, both with one rubrication-red accent used for emphasis, never decoration.

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

    // Night: warm near-black paper, soft cream ink, a brighter rubrication red so the
    // accent still reads against the dark.
    static let dark = Palette(
        paper: Color(hex: 0x1C1813),
        ink: Color(hex: 0xE6DCC6),
        inkSoft: Color(hex: 0xA39A85),
        accent: Color(hex: 0xC8553F),
        gold: Color(hex: 0xC9A968),
        rule: Color(hex: 0xE6DCC6).opacity(0.14),
        rail: Color(hex: 0x262019)
    )
}

// App-wide appearance, persisted. Day = parchment, Night = warm dark.
enum AppearanceMode: String { case light, dark }

final class AppTheme: ObservableObject {
    @Published var mode: AppearanceMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: key) }
    }
    private let key = "appearanceMode.v1"

    init() {
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        mode = AppearanceMode(rawValue: raw) ?? .light
        // Debug hook: LECTIO_DEBUG_DARK launches in night mode (for screenshots).
        if ProcessInfo.processInfo.environment["LECTIO_DEBUG_DARK"] != nil { mode = .dark }
    }

    var palette: Palette { mode == .dark ? .dark : .natural }
    var colorScheme: ColorScheme { mode == .dark ? .dark : .light }
    func toggle() { mode = (mode == .dark) ? .light : .dark }
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
