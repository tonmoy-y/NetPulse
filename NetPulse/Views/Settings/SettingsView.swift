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
        // Same default size as before (460x420) — the point isn't a wider
        // default, it's that .frame(width:height:) with exact values locks
        // the window with no resize handles at all. minWidth/maxWidth (and
        // height) keeps the original look but lets you drag it wider
        // yourself if the "»" tab overflow menu bothers you.
        .frame(minWidth: 460, idealWidth: 460, maxWidth: .infinity,
               minHeight: 420, idealHeight: 420, maxHeight: .infinity)
    }
}
