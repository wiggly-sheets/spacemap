import Foundation
import CoreGraphics

/// Caches CGImage thumbnails for all spaces, captured via SLS on space-change signals.
/// Refreshed on every space_changed signal; served synchronously to CellView.
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    
    private var cache: [Int: CGImage] = [:]
    private let queue = DispatchQueue(label: "com.spacemap.thumbnailcache")
    
    /// Capture all spaces up to maxSpaces and cache the results.
    /// Called on every space_changed signal (background queue).
    func refreshAll(maxSpaces: Int, displayBounds: CGRect) {
        var newCache: [Int: CGImage] = [:]
        for i in 1...maxSpaces {
            if let img = SLSCapture.capture(spaceIndex: i, displayBounds: displayBounds) {
                newCache[i] = img
            }
        }
        queue.sync { cache = newCache }
        NSLog("spacemap/ThumbnailCache: refreshed \(newCache.count)/\(maxSpaces) spaces")
    }
    
    /// Get cached thumbnail for a space. Returns nil if not yet captured.
    func thumbnail(forSpace index: Int) -> CGImage? {
        queue.sync { cache[index] }
    }
}
