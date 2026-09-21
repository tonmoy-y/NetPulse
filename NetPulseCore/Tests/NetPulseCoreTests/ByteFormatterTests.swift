import XCTest
@testable import NetPulseCore

final class ByteFormatterTests: XCTestCase {
    func testZeroBytes() {
        XCTAssertEqual(ByteFormatter.formatBytes(0), "0 B")
    }

    func testBytesUnderKilo() {
        XCTAssertEqual(ByteFormatter.formatBytes(512), "512 B")
    }

    func testKilobytes() {
        XCTAssertEqual(ByteFormatter.formatBytes(2048, decimalPlaces: 1), "2.0 KB")
    }

    func testMegabytes() {
        XCTAssertEqual(ByteFormatter.formatBytes(2_516_582, decimalPlaces: 2), "2.40 MB")
    }

    func testGigabytes() {
        let value = 7.42 * 1024 * 1024 * 1024
        XCTAssertEqual(ByteFormatter.formatBytes(value, decimalPlaces: 2), "7.42 GB")
    }

    func testTerabytes() {
        let value = 2.4 * 1024 * 1024 * 1024 * 1024
        XCTAssertEqual(ByteFormatter.formatBytes(value, decimalPlaces: 1), "2.4 TB")
    }

    func testFormatRateAppendsPerSecond() {
        XCTAssertEqual(ByteFormatter.formatRate(bytesPerSecond: 1024, decimalPlaces: 0), "1 KB/s")
    }

    func testNegativeIsClampedToZero() {
        XCTAssertEqual(ByteFormatter.formatBytes(-100), "0 B")
    }

    func testComponentsSplit() {
        let (value, unit) = ByteFormatter.components(bytes: 393_216, decimalPlaces: 0)
        XCTAssertEqual(value, "384")
        XCTAssertEqual(unit, "KB")
    }
}
