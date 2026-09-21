import Foundation

/// Looks up the device's public IP address. This performs an external
/// network request and is therefore opt-in only — it must never be called
/// unless the user has explicitly enabled it in Privacy settings, and every
/// call site must gate on `AppSettings.privacy.publicIPLookupEnabled`.
enum PublicIPService {
    private static let endpoint = URL(string: "https://api.ipify.org?format=text")!

    static func fetchPublicIP() async -> String? {
        guard let (data, response) = try? await URLSession.shared.data(from: endpoint),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
