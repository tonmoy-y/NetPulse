import Foundation

public enum ConnectionState: String, Codable {
    case connected
    case disconnected
    case connecting
    case limited
}

public struct ConnectionEvent: Codable, Equatable, Identifiable {
    public var id = UUID()
    public let timestamp: Date
    public let state: ConnectionState
    public let interfaceName: String?

    public init(timestamp: Date, state: ConnectionState, interfaceName: String?) {
        self.timestamp = timestamp
        self.state = state
        self.interfaceName = interfaceName
    }
}

public struct ConnectionHistorySummary: Equatable {
    public let disconnectCount: Int
    public let lastDisconnect: Date?
    public let lastReconnect: Date?
    public let totalDowntime: TimeInterval

    public static let empty = ConnectionHistorySummary(disconnectCount: 0, lastDisconnect: nil, lastReconnect: nil, totalDowntime: 0)
}

public enum ConnectionHistoryAnalyzer {
    public static func summarize(_ events: [ConnectionEvent]) -> ConnectionHistorySummary {
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        var disconnectCount = 0
        var lastDisconnect: Date?
        var lastReconnect: Date?
        var totalDowntime: TimeInterval = 0
        var pendingDisconnect: Date?

        for event in sorted {
            switch event.state {
            case .disconnected:
                disconnectCount += 1
                lastDisconnect = event.timestamp
                pendingDisconnect = event.timestamp
            case .connected:
                if let start = pendingDisconnect {
                    totalDowntime += event.timestamp.timeIntervalSince(start)
                    pendingDisconnect = nil
                }
                lastReconnect = event.timestamp
            case .connecting, .limited:
                break
            }
        }

        return ConnectionHistorySummary(
            disconnectCount: disconnectCount,
            lastDisconnect: lastDisconnect,
            lastReconnect: lastReconnect,
            totalDowntime: totalDowntime
        )
    }
}
