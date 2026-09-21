import Foundation
import UserNotifications
import NetPulseCore

/// Evaluates alert rules against live measurements and fires native macOS
/// notifications, respecting each rule's own cooldown so the user is never
/// spammed with repeats.
final class AlertEngine {
    private var rules: [AlertRule]
    private let onRulesChanged: ([AlertRule]) -> Void

    init(rules: [AlertRule], onRulesChanged: @escaping ([AlertRule]) -> Void) {
        self.rules = rules
        self.onRulesChanged = onRulesChanged
        requestAuthorizationIfNeeded()
    }

    func updateRules(_ newRules: [AlertRule]) {
        rules = newRules
    }

    func evaluateThroughput(downloadBps: Double, uploadBps: Double) {
        evaluate(kind: .downloadAbove, measurement: downloadBps) { rule in
            "Download speed reached \(formattedRate(downloadBps))"
        }
        evaluate(kind: .uploadAbove, measurement: uploadBps) { rule in
            "Upload speed reached \(formattedRate(uploadBps))"
        }
    }

    func evaluateLatency(ms: Double) {
        evaluate(kind: .latencyAbove, measurement: ms) { rule in
            "Latency reached \(Int(ms)) ms"
        }
    }

    func evaluatePacketLoss(percent: Double) {
        evaluate(kind: .packetLossAbove, measurement: percent) { rule in
            "Packet loss reached \(String(format: "%.1f", percent))%"
        }
    }

    func evaluateConnection(isConnected: Bool) {
        let kind: AlertKind = isConnected ? .connectionRestored : .connectionLost
        evaluate(kind: kind, measurement: 0) { _ in
            isConnected ? "Internet connection restored" : "Internet connection lost"
        }
    }

    private func evaluate(kind: AlertKind, measurement: Double, message: (AlertRule) -> String) {
        guard let index = rules.firstIndex(where: { $0.kind == kind }) else { return }
        var rule = rules[index]
        guard rule.shouldTrigger(measurement: measurement) else { return }

        rule.lastTriggeredAt = Date()
        rules[index] = rule
        onRulesChanged(rules)

        fireNotification(title: "NetPulse", body: message(rule), playSound: rule.playSound)
    }

    private func fireNotification(title: String, body: String, playSound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = playSound ? .default : nil

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func formattedRate(_ bps: Double) -> String {
        ByteFormatter.formatRate(bytesPerSecond: bps, decimalPlaces: 1)
    }
}
