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
    private var hostingView: NSHostingView<GridView>?
    var onShowSettings: (() -> Void)?
    private var settingsKeyMonitor: Any?
    
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
        
        panel = makePanel()
        guard let panel else { 
            return
        }
        
        // buildGridState derives focusedIndex from spaces query — no separate call needed
        let state = YabaiClient.buildGridState(config: config)
        currentState = state
        dragHandler.cachedWindows = state.windows
        // Capture focused window before HUD renders, so drag handler knows what the user had active.
        if let focusedWindowID = (try? YabaiClient.queryFocusedWindow()) {
            dragHandler.focusedWindowIDAtOpen = focusedWindowID
        }
        refreshThumbnailCache(state: state)
        renderState(state, panel: panel)
        updateCellFrames(state: state, panel: panel)
        dragHandler.start()
        lastFocusedSpaceIndex = state.focusedIndex
        isVisible = true
        resetAutoHideTimer()
        startSettingsKeyMonitor()
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
        hostingView = nil
        
        isVisible = false
        hoveredCell = nil
        currentState = nil
        dragHandler.cellFrames = []
        dragHandler.cachedWindows = []
        dragHandler.focusedWindowIDAtOpen = nil
        stopSettingsKeyMonitor()
    }
    
    // Called by SocketListener — also handles full content refresh (windows moved etc.)
    func refresh() {
        guard isVisible, panel != nil else { return }
        resetAutoHideTimer()
        refreshState()
    }
    
    private func refreshState() {
        guard let panel else { return }
        let state = YabaiClient.buildGridState(config: config)
        currentState = state
        dragHandler.cachedWindows = state.windows
        refreshThumbnailCache(state: state)
        renderState(state, panel: panel)
        updateCellFrames(state: state, panel: panel)
        lastFocusedSpaceIndex = state.focusedIndex
    }
    
    private func renderState(_ state: GridState, panel: NSPanel) {
        let hovered = hoveredCell
        let gridView = GridView(state: state, hoveredCell: hovered, onSelect: { [weak self] index in
            YabaiClient.focusSpace(index)
            self?.hide()
        }, uiScale: config.uiScale, theme: config.theme)
        let size = gridView.idealSize
        
        if let hv = hostingView {
            hv.rootView = gridView
            hv.frame = NSRect(origin: .zero, size: size)
        } else {
            let hv = NSHostingView(rootView: gridView)
            hv.frame = NSRect(origin: .zero, size: size)
            panel.contentView = hv
            hostingView = hv
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

    private func refreshThumbnailCache(state: GridState) {
        guard #available(macOS 14.0, *) else { return }
        guard config.cellStyle == .thumbnails else { return }
        guard let focusedIndex = state.focusedIndex else { return }
        ThumbnailCache.shared.captureActiveSpace(spaceIndex: focusedIndex)
    }

    private func startSettingsKeyMonitor() {
        settingsKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return }
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                DispatchQueue.main.async {
                    self.hide()
                    self.onShowSettings?()
                }
                return
            }
            let code = UInt16(event.keyCode)
            let mods = event.modifierFlags
            let noModifiers = !mods.contains(.control) && !mods.contains(.command) && !mods.contains(.option)
            var dir: Direction? = nil
            if config.useArrowKeys && noModifiers {
                switch code {
                case 123: dir = .left
                case 124: dir = .right
                case 125: dir = .down
                case 126: dir = .up
                default: break
                }
            }
            if dir == nil && config.useVimKeys && noModifiers {
                switch code {
                case 38: dir = .down   // j
                case 40: dir = .up     // k
                case 37: dir = .right  // l
                case 4:  dir = .left   // h
                default: break
                }
            }
            if let d = dir {
                self.navigateSpace(d)
            }
        }
    }

    private func stopSettingsKeyMonitor() {
        if let monitor = settingsKeyMonitor {
            NSEvent.removeMonitor(monitor)
            settingsKeyMonitor = nil
        }
    }

    private enum Direction { case left, right, up, down }

    private func navigateSpace(_ direction: Direction) {
        guard let idx = lastFocusedSpaceIndex else { return }
        let cols = config.cols
        let maxN = config.maxSpaces
        let zero = idx - 1
        let row = zero / cols
        let col = zero % cols
        let rowStart = row * cols + 1
        var target: Int?

        switch direction {
        case .left:
            if col == 0 {
                var rowEnd = rowStart + cols - 1
                if rowEnd > maxN { rowEnd = maxN }
                target = rowEnd
            } else {
                target = idx - 1
            }
        case .right:
            if col == cols - 1 {
                target = rowStart
            } else {
                let next = idx + 1
                target = next > maxN ? rowStart : next
            }
        case .up, .down:
            var columnSpaces: [Int] = []
            var i = col + 1
            while i <= maxN {
                columnSpaces.append(i)
                i += cols
            }
            guard let pos = columnSpaces.firstIndex(of: idx) else { return }
            let n = columnSpaces.count
            let newPos: Int
            if direction == .up {
                newPos = (pos - 1 + n) % n
            } else {
                newPos = (pos + 1) % n
            }
            target = columnSpaces[newPos]
        }

        guard let t = target else { return }
        YabaiClient.focusSpace(t)
    }
    
    private var screenHeight: CGFloat {
        NSScreen.main?.frame.height ?? 0
    }
}
