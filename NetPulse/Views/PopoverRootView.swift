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

            Button("Settings…") { AppWindowRouter.openSettings() }
                .buttonStyle(.link)
                .font(.netPulseSecondary)

            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.link)
                .font(.netPulseSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
