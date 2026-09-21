import Foundation

public struct LatencySample: Codable, Equatable, Identifiable {
    public var id = UUID()
    public let timestamp: Date
    public let host: String
    public let roundTripMs: Double?  // nil = timeout / packet lost

    public init(timestamp: Date, host: String, roundTripMs: Double?) {
        self.timestamp = timestamp
        self.host = host
        self.roundTripMs = roundTripMs
    }
}

public struct LatencyStatistics: Codable, Equatable {
    public var current: Double?
    public var average: Double = 0
    public var minimum: Double = 0
    public var maximum: Double = 0
    public var packetLossPercent: Double = 0
    public var sampleCount: Int = 0

    public init() {}
}

/// Bounded ring-buffer accumulator for latency samples so memory stays flat
/// even when the app runs for days.
public final class LatencyStatisticsAccumulator {
    private let capacity: Int
    private var samples: [LatencySample] = []
    public private(set) var statistics = LatencyStatistics()

    public init(capacity: Int = 500) {
        self.capacity = capacity
    }

    public func record(_ sample: LatencySample) {
        samples.append(sample)
        if samples.count > capacity {
            samples.removeFirst(samples.count - capacity)
        }
        recompute()
    }

    public func reset() {
        samples.removeAll()
        statistics = LatencyStatistics()
    }

    private func recompute() {
        let successful = samples.compactMap(\.roundTripMs)
        statistics.sampleCount = samples.count
        statistics.current = samples.last?.roundTripMs
        statistics.minimum = successful.min() ?? 0
        statistics.maximum = successful.max() ?? 0
        statistics.average = successful.isEmpty ? 0 : successful.reduce(0, +) / Double(successful.count)
        let lost = samples.count - successful.count
        statistics.packetLossPercent = samples.isEmpty ? 0 : (Double(lost) / Double(samples.count)) * 100
    }
}
