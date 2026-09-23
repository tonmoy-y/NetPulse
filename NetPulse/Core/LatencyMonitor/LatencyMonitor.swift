import Foundation
import Combine
import NetPulseCore

/// Measures round-trip latency by invoking the system `/sbin/ping` binary
/// (a single ICMP echo per tick), which avoids needing raw-socket
/// entitlements while still reflecting real network conditions. Polling is
/// deliberately gentle — one packet per configured interval, never a flood.
final class LatencyMonitor: ObservableObject {
    @Published private(set) var statistics = LatencyStatistics()
    @Published private(set) var lastSample: LatencySample?

    private let accumulator = LatencyStatisticsAccumulator()
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.netpulse.latencymonitor", qos: .utility)

    func start(host: String, interval: TimeInterval) {
        stop()
        guard !host.isEmpty else { return }

        let source = DispatchSource.makeTimerSource(queue: queue)
        // Probes don't need to be precisely spaced; the leeway lets macOS
        // batch this wakeup with others.
        source.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(max(250, Int(interval * 1000 * 0.1))))
        source.setEventHandler { [weak self] in
            self?.pingOnce(host: host)
        }
        source.resume()
        timer = source
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func reset() {
        accumulator.reset()
        DispatchQueue.main.async { [weak self] in
            self?.statistics = LatencyStatistics()
            self?.lastSample = nil
        }
    }

    private func pingOnce(host: String) {
        let roundTrip = Self.runPing(host: host, timeoutSeconds: 2)
        let sample = LatencySample(timestamp: Date(), host: host, roundTripMs: roundTrip)
        accumulator.record(sample)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lastSample = sample
            self.statistics = self.accumulator.statistics
        }
    }

    /// Runs a single ICMP echo via the system ping utility and parses the
    /// round-trip time out of its stdout, e.g. "time=8.421 ms".
    private static func runPing(host: String, timeoutSeconds: Int) -> Double? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-t", "\(timeoutSeconds)", host]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { return nil }
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        // ping reports sub-millisecond replies as "time<1 ms" rather than
        // "time=0.4 ms". Without this they'd parse as nil and be counted as
        // lost packets, inflating the packet-loss figure on fast links.
        if output.contains("time<1 ms") { return 0.5 }

        guard let range = output.range(of: "time="),
              let end = output[range.upperBound...].firstIndex(of: " ") else { return nil }

        let numberString = output[range.upperBound..<end]
        return Double(numberString)
    }
}
