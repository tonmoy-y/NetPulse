import Foundation
import AppKit

enum SelfUpdateState: Equatable {
    case idle
    case downloading
    case installing
    case readyToRelaunch
    case failed(String)
}

enum SelfUpdateError: LocalizedError {
    case appNotFoundInImage
    case notInstalledInWritableLocation
    case mountFailed(String)

    var errorDescription: String? {
        switch self {
        case .appNotFoundInImage:
            return "The downloaded disk image didn't contain NetPulse.app."
        case .notInstalledInWritableLocation:
            return "NetPulse isn't in a location it can update itself (e.g. still running from a mounted disk image). Move it to Applications, or use the manual download link."
        case .mountFailed(let detail):
            return "Couldn't open the downloaded update: \(detail)"
        }
    }
}

/// Installs a NetPulse update in place: downloads the release DMG, mounts
/// it, swaps the running app bundle for the new one, and relaunches — so
/// "Update Now" actually updates the app instead of just opening a web page.
///
/// This trusts the same GitHub release URL the manual download path already
/// points at (HTTPS to GitHub, the same source `brew install --cask
/// netpulse` and the direct .dmg download use) — there is no separate
/// cryptographic update-signature scheme here, consistent with NetPulse
/// being ad-hoc signed rather than notarized. If that's ever not sufficient,
/// swapping to a full Sparkle-based updater with signed appcasts is the
/// natural next step.
@MainActor
final class SelfUpdateInstaller: ObservableObject {
    @Published private(set) var state: SelfUpdateState = .idle

    func update(from downloadURL: URL) {
        guard state == .idle || isTerminal(state) else { return }
        state = .downloading

        Task {
            do {
                let dmgURL = try await download(from: downloadURL)
                try await install(dmgAt: dmgURL)
                state = .readyToRelaunch
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func relaunch() {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [bundlePath]
        try? task.run()
        NSApp.terminate(nil)
    }

    func reset() {
        state = .idle
    }

    private func isTerminal(_ state: SelfUpdateState) -> Bool {
        switch state {
        case .readyToRelaunch, .failed: return true
        default: return false
        }
    }

    // MARK: - Steps

    private func download(from url: URL) async throws -> URL {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        // The system gives us a temp file it will clean up; move it somewhere
        // we control for the lifetime of the mount/copy below.
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("NetPulseUpdate-\(UUID().uuidString).dmg")
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    private func install(dmgAt dmgURL: URL) async throws {
        state = .installing

        let currentAppURL = Bundle.main.bundleURL
        guard FileManager.default.isWritableFile(atPath: currentAppURL.deletingLastPathComponent().path) else {
            throw SelfUpdateError.notInstalledInWritableLocation
        }

        let mountPoint = FileManager.default.temporaryDirectory.appendingPathComponent("NetPulseUpdateMount-\(UUID().uuidString)")

        try await Self.runProcess("/usr/bin/hdiutil", ["attach", dmgURL.path, "-nobrowse", "-readonly", "-mountpoint", mountPoint.path])
        defer {
            Task.detached { try? await Self.runProcess("/usr/bin/hdiutil", ["detach", mountPoint.path, "-quiet"]) }
            try? FileManager.default.removeItem(at: dmgURL)
        }

        let sourceApp = mountPoint.appendingPathComponent("NetPulse.app")
        guard FileManager.default.fileExists(atPath: sourceApp.path) else {
            throw SelfUpdateError.appNotFoundInImage
        }

        let backupURL = currentAppURL.deletingLastPathComponent()
            .appendingPathComponent("NetPulse.app.updating-\(UUID().uuidString)")

        // Move the running app aside rather than deleting it outright, so a
        // failed copy can be rolled back instead of leaving no app at all.
        try FileManager.default.moveItem(at: currentAppURL, to: backupURL)
        do {
            try FileManager.default.copyItem(at: sourceApp, to: currentAppURL)
            try? FileManager.default.removeItem(at: backupURL)
        } catch {
            try? FileManager.default.removeItem(at: currentAppURL)
            try FileManager.default.moveItem(at: backupURL, to: currentAppURL)
            throw error
        }
    }

    private static func runProcess(_ launchPath: String, _ arguments: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launchPath)
            process.arguments = arguments

            let errorPipe = Pipe()
            process.standardError = errorPipe

            process.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.resume(throwing: SelfUpdateError.mountFailed(message?.isEmpty == false ? message! : "exit code \(proc.terminationStatus)"))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
