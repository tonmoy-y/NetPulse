import Foundation

public enum RefreshInterval: Double, Codable, CaseIterable, Identifiable, Hashable {
    case ms100 = 0.1
    case ms250 = 0.25
    case ms500 = 0.5
    case s1 = 1.0
    case s2 = 2.0
    case s5 = 5.0

    public var id: Double { rawValue }

    public var label: String {
        switch self {
        case .ms100: return "100 ms"
        case .ms250: return "250 ms"
        case .ms500: return "500 ms"
        case .s1: return "1 second"
        case .s2: return "2 seconds"
        case .s5: return "5 seconds"
        }
    }
}

public enum GraphTimeWindow: Double, Codable, CaseIterable, Identifiable, Hashable {
    case s30 = 30
    case m1 = 60
    case m5 = 300
    case m15 = 900
    case h1 = 3600

    public var id: Double { rawValue }

    public var label: String {
        switch self {
        case .s30: return "30 seconds"
        case .m1: return "1 minute"
        case .m5: return "5 minutes"
        case .m15: return "15 minutes"
        case .h1: return "1 hour"
        }
    }
}

public enum PingTarget: String, Codable, CaseIterable, Identifiable, Hashable {
    case cloudflare = "1.1.1.1"
    case google = "8.8.8.8"
    case quad9 = "9.9.9.9"
    case custom

    public var id: String { rawValue }
}

public struct LatencySettings: Codable, Equatable {
    public var target: PingTarget = .cloudflare
    public var customHost: String = ""
    public var intervalSeconds: Double = 5
    public var isEnabled: Bool = true

    public init() {}

    public var resolvedHost: String {
        target == .custom ? customHost : target.rawValue
    }
}

public struct DataUsageSettings: Codable, Equatable {
    public var persistAcrossLaunches: Bool = true
    public var retentionDays: Int = 90

    public init() {}
}

public struct PrivacySettings: Codable, Equatable {
    public var publicIPLookupEnabled: Bool = false
    public var speedTestEnabled: Bool = true

    public init() {}
}

public struct AppSettings: Codable, Equatable {
    public var refreshInterval: RefreshInterval = .ms500
    public var launchAtLogin: Bool = false
    public var startHidden: Bool = false
    public var isMonitoringPaused: Bool = false

    public var menuBar: MenuBarDisplayOptions = MenuBarDisplayOptions()
    public var interfaceSelection: InterfaceSelectionMode = .auto
    public var showConnectionStateInMenuBar: Bool = true

    public var graphTimeWindow: GraphTimeWindow = .m5
    public var showDownloadInGraph: Bool = true
    public var showUploadInGraph: Bool = true

    public var dataUsage: DataUsageSettings = DataUsageSettings()
    public var latency: LatencySettings = LatencySettings()
    public var qualityThresholds: NetworkQualityThresholds = NetworkQualityThresholds()
    public var privacy: PrivacySettings = PrivacySettings()

    public var alertRules: [AlertRule] = AppSettings.defaultAlertRules

    public init() {}

    public static let defaultAlertRules: [AlertRule] = [
        AlertRule(kind: .downloadAbove, isEnabled: false, thresholdValue: 100 * 1024 * 1024),
        AlertRule(kind: .uploadAbove, isEnabled: false, thresholdValue: 20 * 1024 * 1024),
        AlertRule(kind: .latencyAbove, isEnabled: false, thresholdValue: 100),
        AlertRule(kind: .packetLossAbove, isEnabled: false, thresholdValue: 5),
        AlertRule(kind: .connectionLost, isEnabled: true, thresholdValue: 0),
        AlertRule(kind: .connectionRestored, isEnabled: true, thresholdValue: 0)
    ]
}
