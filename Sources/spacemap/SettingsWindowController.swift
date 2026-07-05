import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    convenience init() {
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 660),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Settings Window")
        window.title = "spacemap Settings"
        window.contentViewController = hostingController
        self.init(window: window)
    }
    
    func showWindow() {
        super.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}