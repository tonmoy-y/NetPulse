import Foundation
import Combine
import NetPulseCore

/// Tracks connect/disconnect events over time so the popup can show a simple
/// history and uptime summary.
final class ConnectionHistoryStore: ObservableObject {
    @Published private(set) var events: [ConnectionEvent] = []
    @Published private(set) var summary: ConnectionHistorySummary = .empty

    private let fileName = "connection_history.json"
    private let persistence: PersistenceController
    private let maxRetainedEvents = 500
    private var lastState: ConnectionState?

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        self.events = persistence.load([ConnectionEvent].self, fileName: fileName) ?? []
        recomputeSummary()
    }

    func record(isConnected: Bool, interfaceName: String?, at date: Date = Date()) {
        let state: ConnectionState = isConnected ? .connected : .disconnected
        guard state != lastState else { return }
        lastState = state

        let event = ConnectionEvent(timestamp: date, state: state, interfaceName: interfaceName)
        events.append(event)
        if events.count > maxRetainedEvents {
            events.removeFirst(events.count - maxRetainedEvents)
        }
        recomputeSummary()
        persistence.save(events, fileName: fileName)
    }

    func clear() {
        events.removeAll()
        lastState = nil
        recomputeSummary()
        persistence.save(events, fileName: fileName)
    }

    private func recomputeSummary() {
        summary = ConnectionHistoryAnalyzer.summarize(events)
    }
}
