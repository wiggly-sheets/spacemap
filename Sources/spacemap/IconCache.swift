import AppKit

/// Caches app icons by name to avoid repeated NSWorkspace.icon(forFile:) calls.
final class IconCache {
    static let shared = IconCache()
    private var cache: [String: NSImage] = [:]

    func icon(for appName: String) -> NSImage? {
        if let cached = cache[appName] { return cached }
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == appName }),
              let bundleURL = app.bundleURL else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: bundleURL.path)
        cache[appName] = icon
        return icon
    }

    func clear() { cache.removeAll() }
}
