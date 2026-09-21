import XCTest
@testable import NetPulseCore

final class ThroughputCalculatorTests: XCTestCase {
    func testBasicDelta() {
        let t0 = Date()
        let t1 = t0.addingTimeInterval(1)
        let prev = InterfaceCounterReading(timestamp: t0, bytesReceived: 1000, bytesSent: 200)
        let cur = InterfaceCounterReading(timestamp: t1, bytesReceived: 3000, bytesSent: 700)

        let sample = ThroughputCalculator.sample(previous: prev, current: cur)
        XCTAssertEqual(sample?.downloadBytesPerSecond, 2000, accuracy: 0.01)
        XCTAssertEqual(sample?.uploadBytesPerSecond, 500, accuracy: 0.01)
    }

    func testZeroElapsedReturnsNil() {
        let t0 = Date()
        let prev = InterfaceCounterReading(timestamp: t0, bytesReceived: 0, bytesSent: 0)
        let cur = InterfaceCounterReading(timestamp: t0, bytesReceived: 100, bytesSent: 100)
        XCTAssertNil(ThroughputCalculator.sample(previous: prev, current: cur))
    }

    func testCounterResetClampsToZero() {
        let t0 = Date()
        let t1 = t0.addingTimeInterval(1)
        // Interface re-attached / counters wrapped: current < previous.
        let prev = InterfaceCounterReading(timestamp: t0, bytesReceived: 5000, bytesSent: 5000)
        let cur = InterfaceCounterReading(timestamp: t1, bytesReceived: 100, bytesSent: 50)

        let sample = ThroughputCalculator.sample(previous: prev, current: cur)
        XCTAssertEqual(sample?.downloadBytesPerSecond, 0)
        XCTAssertEqual(sample?.uploadBytesPerSecond, 0)
    }

    func testVeryHighThroughput() {
        let t0 = Date()
        let t1 = t0.addingTimeInterval(0.5)
        let prev = InterfaceCounterReading(timestamp: t0, bytesReceived: 0, bytesSent: 0)
        let cur = InterfaceCounterReading(timestamp: t1, bytesReceived: 1_000_000_000, bytesSent: 500_000_000)

        let sample = ThroughputCalculator.sample(previous: prev, current: cur)
        XCTAssertEqual(sample?.downloadBytesPerSecond, 2_000_000_000, accuracy: 1)
        XCTAssertEqual(sample?.uploadBytesPerSecond, 1_000_000_000, accuracy: 1)
    }
}
