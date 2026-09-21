import Foundation

public enum AlertKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case downloadAbove
    case uploadAbove
    case latencyAbove
    case packetLossAbove
    case connectionLost
    case connectionRestored

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .downloadAbove: return "Download speed exceeds threshold"
        case .uploadAbove: return "Upload speed exceeds threshold"
        case .latencyAbove: return "Latency exceeds threshold"
        case .packetLossAbove: return "Packet loss exceeds threshold"
        case .connectionLost: return "Internet connection is lost"
        case .connectionRestored: return "Internet connection returns"
        }
    }

    public var usesThreshold: Bool {
        switch self {
        case .connectionLost, .connectionRestored: return false
        default: return true
        }
    }
}

public struct AlertRule: Codable, Equatable, Identifiable {
    public var id: UUID
    public var kind: AlertKind
    public var isEnabled: Bool
    public var thresholdValue: Double   // bytes/sec, ms, or percent depending on kind
    public var cooldownSeconds: TimeInterval
    public var playSound: Bool
    public var lastTriggeredAt: Date?

    public init(id: UUID = UUID(), kind: AlertKind, isEnabled: Bool = true, thresholdValue: Double,
                cooldownSeconds: TimeInterval = 60, playSound: Bool = true, lastTriggeredAt: Date? = nil) {
        self.id = id
        self.kind = kind
        self.isEnabled = isEnabled
        self.thresholdValue = thresholdValue
        self.cooldownSeconds = cooldownSeconds
        self.playSound = playSound
        self.lastTriggeredAt = lastTriggeredAt
    }

    /// Decides whether this rule should fire given a current measurement, honoring
    /// the cooldown so alerts don't spam.
    public func shouldTrigger(measurement: Double, now: Date = Date()) -> Bool {
        guard isEnabled, usesThresholdSatisfied(measurement: measurement) else { return false }
        if let last = lastTriggeredAt, now.timeIntervalSince(last) < cooldownSeconds {
            return false
        }
        return true
    }

    private func usesThresholdSatisfied(measurement: Double) -> Bool {
        guard kind.usesThreshold else { return true }
        return measurement > thresholdValue
    }
}
