import XCTest
@testable import NetPulseCore

final class VersionComparatorTests: XCTestCase {
    func testPatchIsNewer() {
        XCTAssertTrue(VersionComparator.isNewer("v1.0.1", than: "1.0.0"))
    }

    func testSameVersionIsNotNewer() {
        XCTAssertFalse(VersionComparator.isNewer("v1.0.0", than: "1.0.0"))
    }

    func testOlderIsNotNewer() {
        XCTAssertFalse(VersionComparator.isNewer("v0.9.0", than: "1.0.0"))
    }

    func testMajorBeatsMinorAndPatch() {
        XCTAssertTrue(VersionComparator.isNewer("2.0.0", than: "1.9.9"))
    }

    func testMissingComponentsTreatedAsZero() {
        XCTAssertTrue(VersionComparator.isNewer("1.1", than: "1.0.9"))
    }

    func testPrereleaseSuffixIsIgnoredForNumericCompare() {
        XCTAssertFalse(VersionComparator.isNewer("v1.0.0-beta.1", than: "1.0.0"))
    }
}
