import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hud = HUDWindowController()
    private var hotkey: HotkeyMonitor?
    private var socketListener: SocketListener?
    private let socketPath = "/tmp/spacemap_\(NSUserName()).socket"
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        
        // Check if app is in /Applications folder, if not, prompt to move
        checkApplicationLocation()
        
        setupMenubar()
        // Delay slightly so TCC/LaunchServices finishes registering the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let config = ConfigReader.load()
            self.startHotkey(config: config)
            self.socketListener = SocketListener(
                socketPath: self.socketPath,
                healthInterval: config.socketHealthInterval,
                onRefresh: { [weak self] in self?.hud.refresh() },
                onShow: { [weak self] in self?.hud.show() },
                onSettings: { [weak self] in self?.showSettingsWindow() }
            )
            YabaiClient.registerSignals(socketPath: self.socketPath)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        YabaiClient.removeSignals()
        socketListener?.stop()
    }

    private func setupMenubar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "spacemap")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Map", action: #selector(toggleHUD), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Open Accessibility Permissions", action: #selector(openAccessibility), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Restart spacemap", action: #selector(restartApp), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettingsWindow), keyEquivalent: ","))
        menu.addItem(.separator())
        // Launch at Login
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        let isEnabled: Bool
        if #available(macOS 13, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            isEnabled = false
        }
        if isEnabled {
            launchAtLoginItem.state = .on
        }
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit spacemap", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func toggleHUD() { hud.toggle() }

    @objc private func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func restartApp() {
        let bundlePath = Bundle.main.bundleURL.path
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1 && open \"\(bundlePath)\" --args --restarting"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
        NSApp.terminate(nil)
    }

    private func startHotkey(config: GridConfig) {
        let monitor = HotkeyMonitor(config: config.hotkey) { [weak self] in
            self?.hud.toggle()
        }
        monitor.start()
        hotkey = monitor
    }

    @objc private func showSettingsWindow() {
        let settingsWindowController = SettingsWindowController()
        settingsWindowController.showWindow()
    }

    @objc private func toggleLaunchAtLogin() {
        if #available(macOS 13, *) {
            let service = SMAppService.mainApp
            let currentStatus = service.status
            let newEnabled = currentStatus != .enabled
            
            if newEnabled {
                do {
                    try service.register()
                } catch {
                    let alert = NSAlert()
                    alert.alertStyle = .critical
                    alert.messageText = "Cannot enable Launch at Login"
                    alert.informativeText = "Please try again or enable it manually in System Settings > General > Login Items."
                    alert.runModal()
                }
            } else {
                do {
                    try service.unregister()
                } catch {
                    let alert = NSAlert()
                    alert.alertStyle = .critical
                    alert.messageText = "Cannot disable Launch at Login"
                    alert.informativeText = "Please disable it manually in System Settings."
                    alert.runModal()
                }
            }
            
            // Update menu item state
            if let menu = statusItem?.menu {
                for item in menu.items {
                    if item.title == "Launch at Login" {
                        let newStatus: Bool
                        if #available(macOS 13, *) {
                            newStatus = SMAppService.mainApp.status == .enabled
                        } else {
                            newStatus = false
                        }
                        item.state = newStatus ? .on : .off
                        break
                    }
                }
            }
        }
    }

    private func setupLaunchAtLogin(enable: Bool) {
        if #available(macOS 13, *) {
            let service = SMAppService.mainApp
            do {
                if enable {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                print("Failed to \(enable ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            print("Launch at login requires macOS 13 or later")
        }
    }

    private func checkApplicationLocation() {
        let appPath = Bundle.main.bundleURL.path
        let applicationsPath = "/Applications"
        let isInApplications = appPath.hasPrefix(applicationsPath)
        
        // Also check if we need to show the first-launch prompt for Launch at Login
        let defaults = UserDefaults.standard
        let hasAskedLaunchAtLogin = defaults.bool(forKey: "HasAskedLaunchAtLogin")
        
        if !isInApplications {
            showMoveToApplicationsDialog()
        }
        
        if !hasAskedLaunchAtLogin {
            showFirstLaunchLaunchAtLoginPrompt()
            defaults.set(true, forKey: "HasAskedLaunchAtLogin")
        }
    }

    private func showMoveToApplicationsDialog() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Move spacemap to Applications?"
        alert.informativeText = "spacemap should be run from the Applications folder for best performance. Would you like to move it there now?"
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            moveToApplications()
        }
    }

    private func moveToApplications() {
        let source = Bundle.main.bundleURL
        let destination = URL(fileURLWithPath: "/Applications").appendingPathComponent(source.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Moved to Applications"
            alert.informativeText = "spacemap has been copied to the Applications folder. Please quit and relaunch from there."
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Failed to move"
            alert.informativeText = "Could not move spacemap to Applications: \(error.localizedDescription)"
            alert.runModal()
        }
    }

    private func showFirstLaunchLaunchAtLoginPrompt() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Launch at Login?"
        alert.informativeText = "Would you like spacemap to start automatically when you log in?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            setupLaunchAtLogin(enable: true)
        }
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
