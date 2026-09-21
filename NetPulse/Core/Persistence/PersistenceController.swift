import Foundation
import NetPulseCore

/// Thin, dependency-free persistence layer. Preferences go to UserDefaults;
/// larger accumulating datasets (data usage ledger, connection history,
/// lifetime totals) go to small JSON files in Application Support. No
/// database engine is warranted at this scale.
final class PersistenceController {
    static let shared = PersistenceController()

    private let defaults = UserDefaults.standard
    private let settingsKey = "com.netpulse.appSettings"

    private lazy var supportDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("NetPulse", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    private init() {}

    // MARK: - Settings (UserDefaults)

    func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return decoded
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    func resetSettings() {
        defaults.removeObject(forKey: settingsKey)
    }

    // MARK: - Generic JSON file storage

    func load<T: Decodable>(_ type: T.Type, fileName: String) -> T? {
        let url = supportDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, fileName: String) {
        let url = supportDirectory.appendingPathComponent(fileName)
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func delete(fileName: String) {
        let url = supportDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
