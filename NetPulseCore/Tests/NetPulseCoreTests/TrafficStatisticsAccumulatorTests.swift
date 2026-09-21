import XCTest
@testable import NetPulseCore

final class TrafficStatisticsAccumulatorTests: XCTestCase {
    func testAverageAndPeakTrackCorrectly() {
        let acc = TrafficStatisticsAccumulator()
        let now = Date()
        acc.record(NetworkSample(timestamp: now, downloadBytesPerSecond: 100, uploadBytesPerSecond: 10), elapsedSeconds: 1)
        acc.record(NetworkSample(timestamp: now, downloadBytesPerSecond: 300, uploadBytesPerSecond: 30), elapsedSeconds: 1)

        XCTAssertEqual(acc.statistics.averageDownloadBps, 200, accuracy: 0.01)
        XCTAssertEqual(acc.statistics.peakDownloadBps, 300, accuracy: 0.01)
        XCTAssertEqual(acc.statistics.currentUploadBps, 30, accuracy: 0.01)
    }

    func testSessionAndTotalAccumulateBytes() {
        let acc = TrafficStatisticsAccumulator(startingTotals: (downloaded: 1000, uploaded: 500))
        let now = Date()
        acc.record(NetworkSample(timestamp: now, downloadBytesPerSecond: 100, uploadBytesPerSecond: 50), elapsedSeconds: 2)

        XCTAssertEqual(acc.statistics.sessionDownloadedBytes, 200)
        XCTAssertEqual(acc.statistics.sessionUploadedBytes, 100)
        XCTAssertEqual(acc.statistics.totalDownloadedBytes, 1200)
        XCTAssertEqual(acc.statistics.totalUploadedBytes, 600)
    }

    func testResetSessionKeepsTotals() {
        let acc = TrafficStatisticsAccumulator()
        acc.record(NetworkSample(timestamp: Date(), downloadBytesPerSecond: 100, uploadBytesPerSecond: 10), elapsedSeconds: 1)
        acc.resetSession()

        XCTAssertEqual(acc.statistics.sessionDownloadedBytes, 0)
        XCTAssertEqual(acc.statistics.totalDownloadedBytes, 100)
    }

    func testZeroBytesSample() {
        let acc = TrafficStatisticsAccumulator()
        acc.record(NetworkSample(timestamp: Date(), downloadBytesPerSecond: 0, uploadBytesPerSecond: 0), elapsedSeconds: 1)
        XCTAssertEqual(acc.statistics.currentDownloadBps, 0)
        XCTAssertEqual(acc.statistics.peakDownloadBps, 0)
    }
}
