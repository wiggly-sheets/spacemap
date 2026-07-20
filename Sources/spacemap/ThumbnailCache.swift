import Foundation
import CoreGraphics

/// Caches CGImage thumbnails per space. Only captures the active space on each visit.
/// Until a space is visited, its cell shows empty.
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private var cache: [Int: CGImage] = [:]
    private let queue = DispatchQueue(label: "com.spacemap.thumbnailcache")

    /// Capture the currently active space and pin its thumbnail to its cell.
    func captureActiveSpace(spaceIndex: Int, displayBounds: CGRect) {
        guard let img = SLSCapture.capture(spaceIndex: spaceIndex, displayBounds: displayBounds) else {
            NSLog("spacemap/ThumbnailCache: failed to capture space \(spaceIndex)")
            return
        }
        queue.sync { cache[spaceIndex] = img }
        NSLog("spacemap/ThumbnailCache: captured space \(spaceIndex) (\(img.width)x\(img.height))")
    }

    /// Get cached thumbnail for a space. Returns nil if not yet visited.
    func thumbnail(forSpace index: Int) -> CGImage? {
        queue.sync { cache[index] }
    }

    /// Clear all cached thumbnails (e.g. on config change).
    func clear() {
        queue.sync { cache.removeAll() }
    }
}
