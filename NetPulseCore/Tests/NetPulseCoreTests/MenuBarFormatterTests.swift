import XCTest
@testable import NetPulseCore

final class MenuBarFormatterTests: XCTestCase {
    func testArrowsInlineFormat() {
        var options = MenuBarDisplayOptions()
        options.mode = .arrowsInline
        options.decimalPlaces = 1
        options.separator = "  "

        let result = MenuBarFormatter.format(downloadBps: 2.4 * 1024 * 1024, uploadBps: 384 * 1024, options: options)
        XCTAssertEqual(result, "↓ 2.4 MB/s  ↑ 384.0 KB/s")
    }

    func testStackedFormatHasNewline() {
        var options = MenuBarDisplayOptions()
        options.mode = .arrowsStacked
        let result = MenuBarFormatter.format(downloadBps: 1024, uploadBps: 512, options: options)
        XCTAssertTrue(result.contains("\n"))
    }

    func testDownloadOnlyOmitsUpload() {
        var options = MenuBarDisplayOptions()
        options.mode = .downloadOnly
        let result = MenuBarFormatter.format(downloadBps: 1024, uploadBps: 999_999, options: options)
        XCTAssertFalse(result.contains("999"))
        XCTAssertTrue(result.hasPrefix("↓"))
    }

    func testLetteredMode() {
        var options = MenuBarDisplayOptions()
        options.mode = .lettered
        options.decimalPlaces = 0
        let result = MenuBarFormatter.format(downloadBps: 0, uploadBps: 0, options: options)
        XCTAssertEqual(result, "D 0 B/s  U 0 B/s")
    }

    func testHiddenUnitsStripsSuffix() {
        var options = MenuBarDisplayOptions()
        options.mode = .downloadOnly
        options.showUnits = false
        options.decimalPlaces = 0
        let result = MenuBarFormatter.format(downloadBps: 1024, uploadBps: 0, options: options)
        XCTAssertEqual(result, "↓ 1")
    }

    func testCompactModeDropsSpaceAndPerSecondSuffix() {
        var options = MenuBarDisplayOptions()
        options.mode = .downloadOnly
        options.compact = true
        options.decimalPlaces = 1
        let result = MenuBarFormatter.format(downloadBps: 2.4 * 1024 * 1024, uploadBps: 0, options: options)
        XCTAssertEqual(result, "↓ 2.4MB")
    }

    func testNonCompactKeepsFullUnit() {
        var options = MenuBarDisplayOptions()
        options.mode = .downloadOnly
        options.compact = false
        options.decimalPlaces = 1
        let result = MenuBarFormatter.format(downloadBps: 2.4 * 1024 * 1024, uploadBps: 0, options: options)
        XCTAssertEqual(result, "↓ 2.4 MB/s")
    }
}
