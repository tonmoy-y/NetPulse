import Foundation

public enum NetworkQuality: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case offline = "Offline"
}

public struct NetworkQualityThresholds: Codable, Equatable {
    public var excellentLatencyMs: Double = 30
    public var goodLatencyMs: Double = 80
    public var fairLatencyMs: Double = 150
    public var excellentLossPercent: Double = 0
    public var goodLossPercent: Double = 1
    public var fairLossPercent: Double = 5

    public init() {}
}

/// Derives a single coarse quality label from multiple signals rather than
/// from one throughput sample, per design intent (no single-sample verdicts).
public enum NetworkQualityEvaluator {
    public static func evaluate(
        isConnected: Bool,
        averageLatencyMs: Double,
        packetLossPercent: Double,
        recentThroughputStable: Bool,
        thresholds: NetworkQualityThresholds = NetworkQualityThresholds()
    ) -> NetworkQuality {
        guard isConnected else { return .offline }

        let latencyScore: NetworkQuality
        switch averageLatencyMs {
        case ..<thresholds.excellentLatencyMs: latencyScore = .excellent
        case ..<thresholds.goodLatencyMs: latencyScore = .good
        case ..<thresholds.fairLatencyMs: latencyScore = .fair
        default: latencyScore = .poor
        }

        let lossScore: NetworkQuality
        switch packetLossPercent {
        case ...thresholds.excellentLossPercent: lossScore = .excellent
        case ...thresholds.goodLossPercent: lossScore = .good
        case ...thresholds.fairLossPercent: lossScore = .fair
        default: lossScore = .poor
        }

        let combined = worse(latencyScore, lossScore)
        if combined == .excellent && !recentThroughputStable {
            return .good
        }
        return combined
    }

    private static let rank: [NetworkQuality: Int] = [.excellent: 0, .good: 1, .fair: 2, .poor: 3, .offline: 4]

    private static func worse(_ a: NetworkQuality, _ b: NetworkQuality) -> NetworkQuality {
        (rank[a] ?? 0) >= (rank[b] ?? 0) ? a : b
    }
}
