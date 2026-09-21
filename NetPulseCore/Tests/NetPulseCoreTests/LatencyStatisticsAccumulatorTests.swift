import XCTest
@testable import NetPulseCore

final class LatencyStatisticsAccumulatorTests: XCTestCase {
    func testAverageMinMax() {
        let acc = LatencyStatisticsAccumulator()
        let now = Date()
        [10.0, 20.0, 30.0].forEach {
            acc.record(LatencySample(timestamp: now, host: "1.1.1.1", roundTripMs: $0))
        }
        XCTAssertEqual(acc.statistics.average, 20, accuracy: 0.01)
        XCTAssertEqual(acc.statistics.minimum, 10)
        XCTAssertEqual(acc.statistics.maximum, 30)
        XCTAssertEqual(acc.statistics.packetLossPercent, 0)
    }

    func testPacketLossCalculation() {
        let acc = LatencyStatisticsAccumulator()
        let now = Date()
        acc.record(LatencySample(timestamp: now, host: "1.1.1.1", roundTripMs: 10))
        acc.record(LatencySample(timestamp: now, host: "1.1.1.1", roundTripMs: nil))
        acc.record(LatencySample(timestamp: now, host: "1.1.1.1", roundTripMs: nil))
        acc.record(LatencySample(timestamp: now, host: "1.1.1.1", roundTripMs: 10))

        XCTAssertEqual(acc.statistics.packetLossPercent, 50, accuracy: 0.01)
    }

    func testRingBufferCapsMemory() {
        let acc = LatencyStatisticsAccumulator(capacity: 5)
        let now = Date()
        for i in 0..<20 {
            acc.record(LatencySample(timestamp: now, host: "h", roundTripMs: Double(i)))
        }
        XCTAssertEqual(acc.statistics.sampleCount, 5)
        // Only the last 5 (15...19) should remain, so min should be 15.
        XCTAssertEqual(acc.statistics.minimum, 15)
    }

    func testAllLostIsHundredPercent() {
        let acc = LatencyStatisticsAccumulator()
        let now = Date()
        acc.record(LatencySample(timestamp: now, host: "h", roundTripMs: nil))
        XCTAssertEqual(acc.statistics.packetLossPercent, 100)
        XCTAssertNil(acc.statistics.current)
    }
}
