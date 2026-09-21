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
        // An exact .frame(width:height:) locks the window to that fixed
        // size — no resize handles at all. minWidth/maxWidth (and height)
        // instead gives a sensible default that fits all 10 tabs without
        // the "»" overflow menu, while leaving the window freely resizable.
        .frame(minWidth: 700, idealWidth: 760, maxWidth: .infinity,
               minHeight: 420, idealHeight: 460, maxHeight: .infinity)
    }
}
