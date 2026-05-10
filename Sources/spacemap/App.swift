import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hud = HUDWindowController()
    private var hotkey: HotkeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        // Delay slightly so TCC/LaunchServices finishes registering the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startHotkey()
        }
    }

    private func startHotkey() {
        let monitor = HotkeyMonitor { [weak self] focusedIndex in
            self?.hud.toggle(focusedIndex: focusedIndex)
        }
        monitor.start()
        hotkey = monitor
    }
}

@main
struct SpacemapEntry {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
