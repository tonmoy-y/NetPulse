import Foundation

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, menuBar, network, graph, dataUsage, latency, alerts, privacy, advanced, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .menuBar: return "Menu Bar"
        case .network: return "Network"
        case .graph: return "Graph"
        case .dataUsage: return "Data Usage"
        case .latency: return "Latency"
        case .alerts: return "Alerts"
        case .privacy: return "Privacy"
        case .advanced: return "Advanced"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .menuBar: return "menubar.rectangle"
        case .network: return "network"
        case .graph: return "chart.xyaxis.line"
        case .dataUsage: return "chart.pie"
        case .latency: return "timer"
        case .alerts: return "bell"
        case .privacy: return "hand.raised"
        case .advanced: return "slider.horizontal.3"
        case .about: return "info.circle"
        }
    }
}

@MainActor
final class SettingsTabSelection: ObservableObject {
    @Published var selected: SettingsTab = .general
}
