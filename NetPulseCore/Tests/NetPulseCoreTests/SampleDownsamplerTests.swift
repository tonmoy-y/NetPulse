import XCTest
@testable import NetPulseCore

final class SampleDownsamplerTests: XCTestCase {
    private func series(_ values: [Double]) -> [NetworkSample] {
        let start = Date(timeIntervalSince1970: 0)
        return values.enumerated().map { index, value in
            NetworkSample(timestamp: start.addingTimeInterval(Double(index)), downloadBytesPerSecond: value, uploadBytesPerSecond: value / 2)
        }
    }

    func testShortSeriesIsReturnedUnchanged() {
        let input = series([1, 2, 3])
        XCTAssertEqual(SampleDownsampler.downsample(input, maxPoints: 10), input)
    }

    func testLongSeriesIsCappedAtMaxPoints() {
        let input = series(Array(repeating: 1, count: 3600))
        XCTAssertLessThanOrEqual(SampleDownsampler.downsample(input, maxPoints: 120).count, 120)
    }

    func testSpikeInsideABucketIsPreserved() {
        var values = Array(repeating: 10.0, count: 1000)
        values[537] = 99_999
        let output = SampleDownsampler.downsample(series(values), maxPoints: 50)
        XCTAssertEqual(output.map(\.downloadBytesPerSecond).max(), 99_999)
    }

    func testBucketKeepsLastSampleIdentityAndTimestamp() {
        let input = series(Array(repeating: 1, count: 100))
        let output = SampleDownsampler.downsample(input, maxPoints: 10)
        XCTAssertEqual(output.last?.id, input.last?.id)
        XCTAssertEqual(output.last?.timestamp, input.last?.timestamp)
    }

    func testOrderIsPreserved() {
        let output = SampleDownsampler.downsample(series(Array(repeating: 1, count: 500)), maxPoints: 40)
        XCTAssertEqual(output.map(\.timestamp), output.map(\.timestamp).sorted())
    }

    func testNonPositiveMaxPointsReturnsInput() {
        let input = series([1, 2, 3])
        XCTAssertEqual(SampleDownsampler.downsample(input, maxPoints: 0), input)
    }
}
