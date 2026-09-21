import SwiftUI

/// Typography hierarchy for NetPulse, built entirely on the system font
/// (SF Pro) so it always matches macOS and respects Dynamic Type.
extension Font {
    static let netPulseAppTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let netPulseSectionTitle = Font.system(size: 11, weight: .semibold).smallCaps()
    static let netPulseMetricValue = Font.system(size: 22, weight: .bold, design: .rounded).monospacedDigit()
    static let netPulseMetricValueLarge = Font.system(size: 30, weight: .bold, design: .rounded).monospacedDigit()
    static let netPulseMetricLabel = Font.system(size: 11, weight: .medium)
    static let netPulseBody = Font.system(size: 12, weight: .regular)
    static let netPulseSecondary = Font.system(size: 11, weight: .regular)
    static let netPulseCaption = Font.system(size: 10, weight: .regular)
    static let netPulseSettingsLabel = Font.system(size: 12, weight: .medium)
}
