import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    convenience init() {
        let hostingController = NSHostingController(rootView: SettingsView())
        let windowRect = NSRect(x: 0, y: 0, width: 520, height: 800)
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Settings Window")
        window.title = "spacemap Settings"
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 500, height: 700)
        self.init(window: window)
    }
    
    func showWindow() {
        super.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}