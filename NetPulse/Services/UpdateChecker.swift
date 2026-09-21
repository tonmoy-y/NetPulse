import Foundation
import NetPulseCore

enum UpdateCheckState: Equatable {
    case idle
    case checking
    case upToDate(checkedAt: Date)
    case updateAvailable(version: String, releaseURL: URL)
    case failed(String)

    static func == (lhs: UpdateCheckState, rhs: UpdateCheckState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.checking, .checking): return true
        case (.upToDate, .upToDate): return true
        case (.updateAvailable(let a, let au), .updateAvailable(let b, let bu)): return a == b && au == bu
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

/// Checks GitHub Releases for a newer NetPulse version. This is the app's
/// only "phone home" beyond the opt-in public IP lookup and manual speed
/// test — it sends a single anonymous GET to the public GitHub API (no
/// identifying data, no analytics payload) and can be turned off entirely
/// in Settings → General. It never downloads or installs anything itself;
/// it just tells you a new version exists and links to the release page,
/// where the existing "Publishing a release" / Homebrew tap flow takes over.
@MainActor
final class UpdateChecker: ObservableObject {
    @Published private(set) var state: UpdateCheckState = .idle

    private let releasesAPIURL = URL(string: "https://api.github.com/repos/tonmoy-y/NetPulse/releases/latest")!
    private let currentVersion: String

    init(currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0") {
        self.currentVersion = currentVersion
    }

    func checkForUpdates() {
        guard state != .checking else { return }
        state = .checking

        Task {
            do {
                var request = URLRequest(url: releasesAPIURL)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    state = .failed("No published release found yet.")
                    return
                }

                let payload = try JSONDecoder().decode(GitHubRelease.self, from: data)
                if VersionComparator.isNewer(payload.tagName, than: currentVersion),
                   let url = URL(string: payload.htmlURL) {
                    state = .updateAvailable(version: payload.tagName, releaseURL: url)
                } else {
                    state = .upToDate(checkedAt: Date())
                }
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }
}
