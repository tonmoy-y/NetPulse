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
            // Explicit tint instead of leaving the segmented control's
            // selection highlight to the ambient system accent color: that
            // color is resolved from a dynamic NSColor tied to the window's
            // appearance, which is reported to briefly show the wrong value
            // right after a MenuBarExtra popover first appears and only
            // self-correct once some unrelated AppKit event forces a
            // recompute — this pins it to the brand color from frame one.
            .tint(Color.netPulsePrimary)
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Divider().padding(.top, 10)

            // ScrollView has no reliable intrinsic content height of its own,
            // so inside an auto-sizing MenuBarExtra(.window) popover it was
            // collapsing to near-zero height (confirmed: a real screenshot
            // came back 379x120px, just header+tabs+footer, everything
            // between them invisible). A `minHeight` forces real space
            // regardless of what the ScrollView itself reports.
            ScrollView {
                switch selectedTab {
                case .overview: OverviewView()
                case .graph: TrafficGraphView()
                case .statistics: StatisticsView()
                }
            }
            .frame(minHeight: 320, maxHeight: 380)

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
