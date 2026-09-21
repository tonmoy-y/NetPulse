import XCTest
@testable import NetPulseCore

final class NetworkQualityEvaluatorTests: XCTestCase {
    func testOfflineWhenDisconnected() {
        let quality = NetworkQualityEvaluator.evaluate(
            isConnected: false, averageLatencyMs: 10, packetLossPercent: 0, recentThroughputStable: true
        )
        XCTAssertEqual(quality, .offline)
    }

    func testExcellentWithLowLatencyAndNoLoss() {
        let quality = NetworkQualityEvaluator.evaluate(
            isConnected: true, averageLatencyMs: 15, packetLossPercent: 0, recentThroughputStable: true
        )
        XCTAssertEqual(quality, .excellent)
    }

    func testPoorWithHighLatency() {
        let quality = NetworkQualityEvaluator.evaluate(
            isConnected: true, averageLatencyMs: 300, packetLossPercent: 0, recentThroughputStable: true
        )
        XCTAssertEqual(quality, .poor)
    }

    func testHighLossDowngradesQualityEvenWithLowLatency() {
        let quality = NetworkQualityEvaluator.evaluate(
            isConnected: true, averageLatencyMs: 10, packetLossPercent: 8, recentThroughputStable: true
        )
        XCTAssertEqual(quality, .poor)
    }

    func testUnstableThroughputCapsAtGood() {
        let quality = NetworkQualityEvaluator.evaluate(
            isConnected: true, averageLatencyMs: 10, packetLossPercent: 0, recentThroughputStable: false
        )
        XCTAssertEqual(quality, .good)
    }
}
