import Foundation

/// Compares two dotted version strings (optionally prefixed with "v", as
/// GitHub release tags are), used by the update checker to decide whether a
/// release is newer than the running build.
public enum VersionComparator {
    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = components(candidate)
        let b = components(current)
        let count = max(a.count, b.count)
        for i in 0..<count {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    private static func components(_ version: String) -> [Int] {
        var trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            trimmed.removeFirst()
        }
        // Drop any pre-release/build suffix like "-beta.1" or "+build5".
        if let cut = trimmed.firstIndex(where: { $0 == "-" || $0 == "+" }) {
            trimmed = String(trimmed[..<cut])
        }
        return trimmed.split(separator: ".").map { Int($0) ?? 0 }
    }
}
