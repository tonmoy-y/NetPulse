import SwiftUI
import AppKit

/// NetPulse's brand color system. Every token is defined for both Light and
/// Dark Mode so nothing becomes unreadable when the system appearance
/// changes. See Brand/Colors/Palette.md for the full specification.
extension Color {
    /// Builds a dynamic Color that resolves differently in light vs dark appearance.
    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    // MARK: Brand

    /// Primary brand color — "Pulse Teal". Used for the app's identity mark and primary actions.
    static let netPulsePrimary = Color.dynamic(
        light: NSColor(red: 0.071, green: 0.722, blue: 0.686, alpha: 1), // #12B8AF
        dark: NSColor(red: 0.176, green: 0.831, blue: 0.808, alpha: 1)   // #2DD4CE
    )

    /// Secondary brand color — "Signal Indigo". Used sparingly for secondary emphasis.
    static let netPulseSecondary = Color.dynamic(
        light: NSColor(red: 0.290, green: 0.373, blue: 0.910, alpha: 1), // #4A5FE8
        dark: NSColor(red: 0.420, green: 0.486, blue: 1.000, alpha: 1)   // #6B7CFF
    )

    // MARK: Semantic

    static let netPulseDownload = Color.dynamic(
        light: NSColor(red: 0.078, green: 0.722, blue: 0.651, alpha: 1), // #14B8A6
        dark: NSColor(red: 0.176, green: 0.831, blue: 0.769, alpha: 1)   // #2DD4C4
    )

    static let netPulseUpload = Color.dynamic(
        light: NSColor(red: 0.949, green: 0.463, blue: 0.180, alpha: 1), // #F2762E
        dark: NSColor(red: 1.000, green: 0.604, blue: 0.322, alpha: 1)   // #FF9A52
    )

    static let netPulseSuccess = Color.dynamic(
        light: NSColor(red: 0.129, green: 0.639, blue: 0.400, alpha: 1), // #21A366
        dark: NSColor(red: 0.239, green: 0.859, blue: 0.541, alpha: 1)   // #3DDB8A
    )

    static let netPulseWarning = Color.dynamic(
        light: NSColor(red: 0.910, green: 0.639, blue: 0.239, alpha: 1), // #E8A33D
        dark: NSColor(red: 1.000, green: 0.753, blue: 0.349, alpha: 1)   // #FFC059
    )

    static let netPulseError = Color.dynamic(
        light: NSColor(red: 0.886, green: 0.294, blue: 0.294, alpha: 1), // #E24B4B
        dark: NSColor(red: 1.000, green: 0.420, blue: 0.420, alpha: 1)   // #FF6B6B
    )

    // MARK: Surfaces & text (supplement system materials, not a replacement for them)

    static let netPulseSurface = Color.dynamic(
        light: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
        dark: NSColor(red: 0.141, green: 0.141, blue: 0.149, alpha: 1)
    )

    static let netPulseBorder = Color.dynamic(
        light: NSColor(red: 0.898, green: 0.898, blue: 0.918, alpha: 1),
        dark: NSColor(red: 0.220, green: 0.220, blue: 0.227, alpha: 1)
    )

    static let netPulseTextSecondary = Color.dynamic(
        light: NSColor(red: 0.431, green: 0.431, blue: 0.447, alpha: 1),
        dark: NSColor(red: 0.596, green: 0.596, blue: 0.616, alpha: 1)
    )

    static let netPulseTextMuted = Color.dynamic(
        light: NSColor(red: 0.682, green: 0.682, blue: 0.698, alpha: 1),
        dark: NSColor(red: 0.388, green: 0.388, blue: 0.400, alpha: 1)
    )
}
