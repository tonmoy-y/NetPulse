import Foundation

/// Result of a manual, user-initiated speed test. Never invoked automatically.
struct SpeedTestResult: Equatable {
    var downloadBps: Double = 0
    var uploadBps: Double = 0
    var latencyMs: Double = 0
    var jitterMs: Double = 0
}

enum SpeedTestPhase: Equatable {
    case idle
    case measuringLatency
    case measuringDownload(progress: Double)
    case measuringUpload(progress: Double)
    case finished(SpeedTestResult)
    case failed(String)
}

/// A manual bandwidth test that is completely separate from passive
/// monitoring. It consumes real bandwidth and must only run when the user
/// explicitly taps "Start" — it never runs on a timer or at launch.
///
/// It measures against Cloudflare's publicly documented, open speed-test
/// endpoints (speed.cloudflare.com/__down and /__up), the same mechanism
/// used by numerous open-source speed test clients. No proprietary or
/// undocumented service is used.
@MainActor
final class SpeedTestService: ObservableObject {
    @Published private(set) var phase: SpeedTestPhase = .idle

    private let downloadURL = URL(string: "https://speed.cloudflare.com/__down?bytes=25000000")!
    private let uploadURL = URL(string: "https://speed.cloudflare.com/__up")!
    private let latencyProbeURL = URL(string: "https://speed.cloudflare.com/__down?bytes=0")!

    private var session: URLSession = .shared
    private var currentTask: URLSessionTask?

    func start() {
        guard phase == .idle || isTerminal(phase) else { return }
        phase = .measuringLatency
        Task { await run() }
    }

    func cancel() {
        currentTask?.cancel()
        phase = .idle
    }

    private func isTerminal(_ phase: SpeedTestPhase) -> Bool {
        switch phase {
        case .finished, .failed: return true
        default: return false
        }
    }

    private func run() async {
        do {
            let (avgLatency, jitter) = try await measureLatency()
            phase = .measuringDownload(progress: 0)
            let download = try await measureDownload()
            phase = .measuringUpload(progress: 0)
            let upload = try await measureUpload()

            phase = .finished(SpeedTestResult(downloadBps: download, uploadBps: upload, latencyMs: avgLatency, jitterMs: jitter))
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func measureLatency() async throws -> (average: Double, jitter: Double) {
        var samples: [Double] = []
        for _ in 0..<5 {
            let start = Date()
            _ = try await session.data(from: latencyProbeURL)
            samples.append(Date().timeIntervalSince(start) * 1000)
        }
        let average = samples.reduce(0, +) / Double(samples.count)
        let deviations = samples.map { abs($0 - average) }
        let jitter = deviations.reduce(0, +) / Double(deviations.count)
        return (average, jitter)
    }

    private func measureDownload() async throws -> Double {
        let start = Date()
        let (bytesTransferred, _) = try await session.data(from: downloadURL)
        let elapsed = max(0.001, Date().timeIntervalSince(start))
        return Double(bytesTransferred.count) / elapsed
    }

    private func measureUpload() async throws -> Double {
        let payload = Data(count: 5_000_000)
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let start = Date()
        _ = try await session.upload(for: request, from: payload)
        let elapsed = max(0.001, Date().timeIntervalSince(start))
        return Double(payload.count) / elapsed
    }
}
