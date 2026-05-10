import AppKit
import SwiftUI

class HUDWindowController {
    private var panel: NSPanel?
    private var isVisible = false
    private var config = ConfigReader.load()

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        config = ConfigReader.load()
        let focusedIndex = YabaiClient.queryFocusedSpaceIndex()

        if panel == nil {
            panel = makePanel()
        }

        guard let panel else { return }

        render(focusedIndex: focusedIndex, panel: panel)
        isVisible = true
    }

    func refresh() {
        guard isVisible, let panel else { return }
        let focused = YabaiClient.queryFocusedSpaceIndex()
        render(focusedIndex: focused, panel: panel)
    }

    private func render(focusedIndex: Int?, panel: NSPanel) {
        let state = YabaiClient.buildGridState(config: config, focusedIndex: focusedIndex)
        let gridView = GridView(state: state)
        let size = gridView.idealSize

        let hostingView = NSHostingView(rootView: gridView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        panel.contentView = hostingView
        panel.setContentSize(size)

        if let screen = NSScreen.main {
            let x = screen.frame.midX - size.width / 2
            let y = screen.frame.midY - size.height / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
        isVisible = false
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
}
