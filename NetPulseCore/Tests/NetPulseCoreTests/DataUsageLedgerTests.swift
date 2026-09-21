import XCTest
@testable import NetPulseCore

final class DataUsageLedgerTests: XCTestCase {
    func testAddBytesAccumulatesPerDay() {
        var ledger = DataUsageLedger()
        ledger.addBytes(downloaded: 100, uploaded: 10, toDay: "2026-09-21")
        ledger.addBytes(downloaded: 200, uploaded: 20, toDay: "2026-09-21")

        let totals = ledger.totals(forDayKeys: ["2026-09-21"])
        XCTAssertEqual(totals.downloadedBytes, 300)
        XCTAssertEqual(totals.uploadedBytes, 30)
    }

    func testTotalsAcrossMultipleDays() {
        var ledger = DataUsageLedger()
        ledger.addBytes(downloaded: 100, uploaded: 10, toDay: "2026-09-20")
        ledger.addBytes(downloaded: 50, uploaded: 5, toDay: "2026-09-21")

        let totals = ledger.totals(forDayKeys: ["2026-09-20", "2026-09-21"])
        XCTAssertEqual(totals.downloadedBytes, 150)
    }

    func testMissingDayKeyContributesZero() {
        let ledger = DataUsageLedger()
        let totals = ledger.totals(forDayKeys: ["2026-01-01"])
        XCTAssertEqual(totals.downloadedBytes, 0)
        XCTAssertEqual(totals.uploadedBytes, 0)
    }

    func testResetClearsAllDays() {
        var ledger = DataUsageLedger()
        ledger.addBytes(downloaded: 1, uploaded: 1, toDay: "2026-09-21")
        ledger.reset()
        XCTAssertTrue(ledger.days.isEmpty)
    }

    func testTrimKeepsOnlySpecifiedKeys() {
        var ledger = DataUsageLedger()
        ledger.addBytes(downloaded: 1, uploaded: 1, toDay: "2026-01-01")
        ledger.addBytes(downloaded: 1, uploaded: 1, toDay: "2026-09-21")
        ledger.trim(keepingDayKeys: ["2026-09-21"])
        XCTAssertEqual(ledger.days.count, 1)
        XCTAssertNotNil(ledger.days["2026-09-21"])
    }

    func testRecentDayKeysCountAndOrder() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 21
        let reference = calendar.date(from: components)!

        let keys = DayKeyFormatter.recentDayKeys(count: 3, endingAt: reference, calendar: calendar)
        XCTAssertEqual(keys, ["2026-09-19", "2026-09-20", "2026-09-21"])
    }
}
