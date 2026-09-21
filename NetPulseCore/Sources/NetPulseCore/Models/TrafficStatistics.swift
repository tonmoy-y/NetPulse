import Foundation

public struct TrafficStatistics: Codable, Equatable {
    public var currentDownloadBps: Double = 0
    public var currentUploadBps: Double = 0
    public var averageDownloadBps: Double = 0
    public var averageUploadBps: Double = 0
    public var peakDownloadBps: Double = 0
    public var peakUploadBps: Double = 0
    public var sessionDownloadedBytes: UInt64 = 0
    public var sessionUploadedBytes: UInt64 = 0
    public var totalDownloadedBytes: UInt64 = 0
    public var totalUploadedBytes: UInt64 = 0

    public init() {}
}

/// Accumulates a running mean/peak/total from a stream of samples without
/// retaining unbounded history (O(1) memory).
public final class TrafficStatisticsAccumulator {
    private var sampleCount: UInt64 = 0
    private var downloadSum: Double = 0
    private var uploadSum: Double = 0
    public private(set) var statistics = TrafficStatistics()

    public init(startingTotals: (downloaded: UInt64, uploaded: UInt64) = (0, 0)) {
        statistics.totalDownloadedBytes = startingTotals.downloaded
        statistics.totalUploadedBytes = startingTotals.uploaded
    }

    /// `elapsedSeconds` is the time this sample represents, used to convert the
    /// instantaneous rate back into a byte delta for totals.
    public func record(_ sample: NetworkSample, elapsedSeconds: TimeInterval) {
        sampleCount += 1
        downloadSum += sample.downloadBytesPerSecond
        uploadSum += sample.uploadBytesPerSecond

        statistics.currentDownloadBps = sample.downloadBytesPerSecond
        statistics.currentUploadBps = sample.uploadBytesPerSecond
        statistics.averageDownloadBps = downloadSum / Double(sampleCount)
        statistics.averageUploadBps = uploadSum / Double(sampleCount)
        statistics.peakDownloadBps = max(statistics.peakDownloadBps, sample.downloadBytesPerSecond)
        statistics.peakUploadBps = max(statistics.peakUploadBps, sample.uploadBytesPerSecond)

        let downloadedDelta = UInt64(max(0, sample.downloadBytesPerSecond * elapsedSeconds))
        let uploadedDelta = UInt64(max(0, sample.uploadBytesPerSecond * elapsedSeconds))
        statistics.sessionDownloadedBytes += downloadedDelta
        statistics.sessionUploadedBytes += uploadedDelta
        statistics.totalDownloadedBytes += downloadedDelta
        statistics.totalUploadedBytes += uploadedDelta
    }

    public func resetSession() {
        statistics.sessionDownloadedBytes = 0
        statistics.sessionUploadedBytes = 0
    }
}
