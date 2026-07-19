import AppKit
import SwiftUI

class HUDWindowController {
    private var panel: NSPanel?
    private var isVisible = false
    private var _config: GridConfig? = nil
    private var config: GridConfig {
        get {
            if let c = _config {
                return c
            } else {
                _config = ConfigReader.load()
                return _config!
            }
        }
        set {
            _config = newValue
        }
    }
    private var hoveredCell: Int? = nil
    // Snapshot of grid state taken when HUD opens; reused for hover rerenders so
    // the thumbnail layout doesn't flicker during a drag and cachedWindows stays stable.
    private var currentState: GridState? = nil
    private var autoHideTimer: Timer?
    private let dragHandler = WindowDragHandler()
    private var lastFocusedSpaceIndex: Int? = nil
    private var isToggling = false   // prevents re-entry during toggle animations
    
    // Tokyo Night colors (approximate)
    private struct ThemeColors {
        static let background = Color(hex: 0x1a1b26)
        static let foreground = Color(hex: 0xa9b1d6)
        static let focused = Color(hex: 0x7aa2f7)
        static let dropTarget = Color(hex: 0xbb9af7)
    }
    
    init() {
        dragHandler.onHoverCell = { [weak self] cell in
            guard let self, isVisible, let state = currentState else { return }
            hoveredCell = cell
            if let p = panel { renderState(state, panel: p) }
            self.resetAutoHideTimer()
        }
        dragHandler.onDropInCell = { [weak self] windowID, spaceIndex in
            guard let self else { return }
            YabaiClient.moveWindow(windowID, toSpace: spaceIndex)
            hoveredCell = nil
            refreshState()
            resetAutoHideTimer()
        }
    }
    
    func toggle() {
        guard !isToggling else { 
            NSLog("spacemap/HUD: toggle ignored, isToggling=\(isToggling)")
            return 
        }
        NSLog("spacemap/HUD: toggle called, isVisible=\(isVisible)")
        isToggling = true
        if isVisible { hide() } else { show() }
        // Reset isToggling after a short delay to allow for animation settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isToggling = false
        }
    }
    
    func show() {
        guard !isVisible else { 
            // Already showing; do nothing
            return
        }
        NSLog("spacemap/HUD: show() called")
        reloadConfig()
        let focused = YabaiClient.queryFocusedSpaceIndex()
        
        panel = makePanel()
        guard let panel else { 
            return
        }
        
        let state = YabaiClient.buildGridState(config: config, focusedIndex: focused)
        currentState = state
        dragHandler.cachedWindows = state.windows
        // Capture focused window before HUD renders, so drag handler knows what the user had active.
        if let focusedWindowID = (try? YabaiClient.queryFocusedWindow()) {
            dragHandler.focusedWindowIDAtOpen = focusedWindowID
        }
        renderState(state, panel: panel)
        updateCellFrames(state: state, panel: panel)
        dragHandler.start()
        lastFocusedSpaceIndex = focused
        isVisible = true
        resetAutoHideTimer()
    }
    
    func hide() {
        guard isVisible else { 
            // Already hidden; do nothing
            return
        }
        NSLog("spacemap/HUD: hide() called")
        dragHandler.stop()
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        
        if let p = panel {
            p.orderOut(nil)
            p.close()
        }
        panel = nil
        
        isVisible = false
        hoveredCell = nil
        currentState = nil
        dragHandler.cellFrames = []
        dragHandler.cachedWindows = []
        dragHandler.focusedWindowIDAtOpen = nil
    }
    
    // Called by SocketListener on space_changed. Only updates if HUD is already visible.
    func refresh() {
        guard isVisible, panel != nil else { return }
        refreshState()
    }
    
    private func refreshState() {
        guard let panel else { return }
        let focused = YabaiClient.queryFocusedSpaceIndex()
        let state = YabaiClient.buildGridState(config: config, focusedIndex: focused)
        currentState = state
        dragHandler.cachedWindows = state.windows
        renderState(state, panel: panel)
        updateCellFrames(state: state, panel: panel)
        lastFocusedSpaceIndex = focused
    }
    
    private func renderState(_ state: GridState, panel: NSPanel) {
        let hovered = hoveredCell
        let gridView = GridView(state: state, hoveredCell: hovered, onSelect: { [weak self] index in
            YabaiClient.focusSpace(index)
            self?.hide()
        }, uiScale: config.uiScale, theme: config.theme)
        let size = gridView.idealSize
        
        if let existingHostingView = panel.contentView as? NSHostingView<GridView> {
            existingHostingView.rootView = gridView
            existingHostingView.frame.size = size
        } else {
            let hostingView = NSHostingView(rootView: gridView)
            hostingView.frame = NSRect(origin: .zero, size: size)
            panel.contentView = hostingView
        }
        
        panel.setContentSize(size)
        
        if let screen = NSScreen.main {
            let x = screen.frame.midX - size.width / 2
            let y = screen.frame.midY - size.height / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.orderFrontRegardless()
    }
    
    private func updateCellFrames(state: GridState, panel: NSPanel) {
        let scale = config.uiScale
        let cellWidth: CGFloat = 80 * scale * 3
        let cellHeight: CGFloat = 50 * scale * 3
        let gap: CGFloat = 6 * scale * 3
        let padding: CGFloat = 12 * scale * 3
        let slotWidth = cellWidth + gap
        let slotHeight = cellHeight + gap
        
        // Compute visible cells same as GridView
        let maxN = min(config.maxSpaces, 16)
        let all = (1...maxN).map { $0 }
        let cells: [Int]
        if config.showMode == .active {
            let activeSet = Set(state.spaces.map { $0.index })
            cells = all.filter { activeSet.contains($0) }
        } else {
            cells = all
        }
        
        let cols = min(config.cols, cells.count)
        let rowCount = (cells.count + cols - 1) / cols
        
        var frames: [(spaceIndex: Int, frame: CGRect)] = []
        let origin = panel.frame.origin
        let totalHeight = CGFloat(rowCount) * (cellHeight + gap) - gap + padding * 2
        
        for (i, spaceIndex) in cells.enumerated() {
            let row = i / cols
            let col = i % cols
            let x = origin.x + padding + CGFloat(col) * (cellWidth + gap) - gap / 2
            let appKitSlotTop = origin.y + totalHeight - padding - CGFloat(row) * (cellHeight + gap) - gap / 2
            let cgY = screenHeight - appKitSlotTop
            frames.append((spaceIndex: spaceIndex, frame: CGRect(x: x, y: cgY, width: slotWidth, height: slotHeight)))
        }
        
        dragHandler.cellFrames = frames
    }
    
    private func makePanel() -> NSPanel {
        let p = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        p.hasShadow = true
        return p
    }
    
    private func resetAutoHideTimer() {
        autoHideTimer?.invalidate()
        if config.autoHideTimeout > 0 {
            autoHideTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.autoHideTimeout), repeats: false) { [weak self] _ in
                self?.hide()
            }
        }
    }
    
    func reloadConfig() {
        _config = nil
    }
    
    private var screenHeight: CGFloat {
        NSScreen.main?.frame.height ?? 0
    }
}
