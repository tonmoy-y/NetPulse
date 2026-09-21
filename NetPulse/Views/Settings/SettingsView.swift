import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gearshape") }

            MenuBarSettingsTab()
                .tabItem { Label("Menu Bar", systemImage: "menubar.rectangle") }

            NetworkSettingsTab()
                .tabItem { Label("Network", systemImage: "network") }

            GraphSettingsTab()
                .tabItem { Label("Graph", systemImage: "chart.xyaxis.line") }

            DataUsageSettingsTab()
                .tabItem { Label("Data Usage", systemImage: "chart.pie") }

            LatencySettingsTab()
                .tabItem { Label("Latency", systemImage: "timer") }

            AlertsSettingsTab()
                .tabItem { Label("Alerts", systemImage: "bell") }

            PrivacySettingsTab()
                .tabItem { Label("Privacy", systemImage: "hand.raised") }

            AdvancedSettingsTab()
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }

            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        // 460pt was too narrow for all 10 tabs to show inline — the last
        // four (Alerts, Privacy, Advanced, About) were getting pushed into
        // a "»" overflow menu, which reads as "disabled" at a glance even
        // though every tab behind it works fine. Wide enough to fit all 10
        // tab items without that overflow.
        .frame(width: 760, height: 460)
    }
}
