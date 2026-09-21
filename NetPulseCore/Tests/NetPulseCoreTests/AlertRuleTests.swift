import XCTest
@testable import NetPulseCore

final class AlertRuleTests: XCTestCase {
    func testTriggersWhenAboveThreshold() {
        let rule = AlertRule(kind: .downloadAbove, thresholdValue: 100)
        XCTAssertTrue(rule.shouldTrigger(measurement: 150))
    }

    func testDoesNotTriggerWhenBelowThreshold() {
        let rule = AlertRule(kind: .downloadAbove, thresholdValue: 100)
        XCTAssertFalse(rule.shouldTrigger(measurement: 50))
    }

    func testDisabledRuleNeverTriggers() {
        let rule = AlertRule(kind: .downloadAbove, isEnabled: false, thresholdValue: 100)
        XCTAssertFalse(rule.shouldTrigger(measurement: 999))
    }

    func testCooldownSuppressesRepeatedTrigger() {
        let now = Date()
        let rule = AlertRule(kind: .latencyAbove, thresholdValue: 50, cooldownSeconds: 60, lastTriggeredAt: now)
        XCTAssertFalse(rule.shouldTrigger(measurement: 100, now: now.addingTimeInterval(10)))
        XCTAssertTrue(rule.shouldTrigger(measurement: 100, now: now.addingTimeInterval(61)))
    }

    func testConnectionEventsIgnoreThreshold() {
        let rule = AlertRule(kind: .connectionLost, thresholdValue: 0)
        XCTAssertTrue(rule.shouldTrigger(measurement: 0))
    }
}
