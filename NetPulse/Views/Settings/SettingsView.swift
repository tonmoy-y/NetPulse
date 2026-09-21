import SwiftUI

/// Tab switching is driven by a real NSToolbar (see SettingsWindowController)
/// rather than SwiftUI's TabView. TabView's own tab bar has no native
/// overflow handling outside of an actual `Settings` scene — with 10 tabs at
/// a normal window width it was truncating the trailing tabs with no way to
/// reach them at all. NSToolbar gets AppKit's real, native overflow chevron
/// for free, the same mechanism System Settings itself uses.
struct SettingsView: View {
    @EnvironmentObject private var tabSelection: SettingsTabSelection

    var body: some View {
        Group {
            switch tabSelection.selected {
            case .general: GeneralSettingsTab()
            case .menuBar: MenuBarSettingsTab()
            case .network: NetworkSettingsTab()
            case .graph: GraphSettingsTab()
            case .dataUsage: DataUsageSettingsTab()
            case .latency: LatencySettingsTab()
            case .alerts: AlertsSettingsTab()
            case .privacy: PrivacySettingsTab()
            case .advanced: AdvancedSettingsTab()
            case .about: AboutTab()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
