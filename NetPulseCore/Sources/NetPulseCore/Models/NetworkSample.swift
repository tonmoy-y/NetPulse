import Foundation

/// One instantaneous throughput reading, derived from the delta between two
/// consecutive raw interface byte counters divided by elapsed time.
public struct NetworkSample: Codable, Equatable, Identifiable {
    public var id: UUID
    public let timestamp: Date
    public let downloadBytesPerSecond: Double
    public let uploadBytesPerSecond: Double

    public init(id: UUID = UUID(), timestamp: Date, downloadBytesPerSecond: Double, uploadBytesPerSecond: Double) {
        self.id = id
        self.timestamp = timestamp
        self.downloadBytesPerSecond = max(0, downloadBytesPerSecond)
        self.uploadBytesPerSecond = max(0, uploadBytesPerSecond)
    }
}

/// Raw cumulative byte counters read from a network interface at a point in time.
public struct InterfaceCounterReading: Equatable {
    public let timestamp: Date
    public let bytesReceived: UInt64
    public let bytesSent: UInt64

    public init(timestamp: Date, bytesReceived: UInt64, bytesSent: UInt64) {
        self.timestamp = timestamp
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
    }
}

/// Computes a throughput sample from two raw counter readings, correctly
/// handling counter resets (e.g. interface re-attach) by clamping to zero.
public enum ThroughputCalculator {
    public static func sample(previous: InterfaceCounterReading, current: InterfaceCounterReading) -> NetworkSample? {
        let elapsed = current.timestamp.timeIntervalSince(previous.timestamp)
        guard elapsed > 0 else { return nil }

        let downloadDelta: UInt64 = current.bytesReceived >= previous.bytesReceived
            ? current.bytesReceived - previous.bytesReceived : 0
        let uploadDelta: UInt64 = current.bytesSent >= previous.bytesSent
            ? current.bytesSent - previous.bytesSent : 0

        return NetworkSample(
            timestamp: current.timestamp,
            downloadBytesPerSecond: Double(downloadDelta) / elapsed,
            uploadBytesPerSecond: Double(uploadDelta) / elapsed
        )
    }
}
