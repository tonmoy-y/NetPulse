import SwiftUI

enum PopoverTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case graph = "Graph"
    case statistics = "Statistics"

    var id: String { rawValue }
}

struct PopoverRootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: PopoverTab = .overview

    var body: some View {
        VStack(spacing: 0) {
            header

            Picker("", selection: $selectedTab) {
                ForEach(PopoverTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Divider().padding(.top, 10)

            ScrollView {
                switch selectedTab {
                case .overview: OverviewView()
                case .graph: TrafficGraphView()
                case .statistics: StatisticsView()
                }
            }
            .frame(maxHeight: 380)

            Divider()
            footer
        }
        .background(Color.netPulseSurface)
    }

    private var header: some View {
        HStack(spacing: 8) {
            NetPulseMark(size: 18)
            Text("NetPulse")
                .font(.netPulseAppTitle)
            Spacer()
            QualityBadge(quality: appState.networkQuality)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private var footer: some View {
        HStack {
            Button("Speed Test") { selectedTab = .statistics }
                .buttonStyle(.link)
                .font(.netPulseSecondary)

            Spacer()

            settingsButton

            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.link)
                .font(.netPulseSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // `SettingsLink` (macOS 14+) is the only reliable way to open the
    // SwiftUI Settings scene from outside it — confirmed the hard way: the
    // previous `NSApp.sendAction(Selector(("showSettingsWindow:")), ...)`
    // hack logs a `fault`-level runtime-issues warning ("Please use
    // SettingsLink for opening the Settings scene") and does not reliably
    // open the window on current macOS. Deployment target for this file's
    // behavior is effectively 14+; 13 falls back to the old best-effort hack.
    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Settings…")
            }
            .buttonStyle(.link)
            .font(.netPulseSecondary)
        } else {
            Button("Settings…") { AppWindowRouter.openSettings() }
                .buttonStyle(.link)
                .font(.netPulseSecondary)
        }
    }
}
