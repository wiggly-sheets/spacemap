import SwiftUI
import Foundation
import CoreGraphics
import AppKit
import ServiceManagement

struct SettingsView: View {
    @State private var cols: Int = 8
    @State private var rows: Int = 2
    @State private var cellStyle: CellStyle = .rects
    @State private var hotkeyString: String = "ctrl+pgdn"
    @State private var socketHealthInterval: Int = 60
    @State private var uiScale: Double = 1.0
    @State private var autoHideTimeout: Int = 0
    @State private var theme: String = "default"
    @State private var showMode: ShowMode = .all
    @State private var maxSpaces: Int = 16
    @State private var backgroundAlpha: Double = 0.3
    @State private var mode: ThemeMode = .auto
    @State private var iconScale: Double = 1.0
    @State private var showNames: Bool = true
    @State private var isRecording = false
    @State private var monitor: Any?
    
    private let socketHealthOptions = [15, 30, 45, 60]
    
    private let configPath = NSString(string: "~/.config/spacemap/config").expandingTildeInPath
    
private var maxSpacesOptions: [Int] { Array(1...16) }

private var backgroundTransparencySteps: [Double] {
        // 10 steps: 0.00 to 1.00, approximately equal increments
        [0.00, 0.11, 0.22, 0.33, 0.44, 0.55, 0.66, 0.77, 0.88, 1.00]
    }
    
    private var uiScaleSteps: [Double] {
        // 10 steps: 0.2 is middle (index 5)
        [0.05, 0.08, 0.11, 0.14, 0.17, 0.2, 0.3, 0.4, 0.5, 0.6]
    }
    
    private var iconScaleSteps: [Double] {
        // 10 steps: 0.7 is middle (index 5)
        [0.3, 0.38, 0.46, 0.54, 0.62, 0.7, 0.9, 1.1, 1.3, 1.5]
    }
    
    private func nearest<T: FixedWidthInteger>(to value: T, from sorted: [T]) -> T {
        guard var closest = sorted.first else { return value }
        for item in sorted {
            let diff = item > value ? item - value : value - item
            let closestDiff = closest > value ? closest - value : value - closest
            if diff < closestDiff {
                closest = item
            }
        }
        return closest
    }
    
    private func nearest<T: BinaryFloatingPoint>(to value: T, from sorted: [T]) -> T {
        guard var closest = sorted.first else { return value }
        for item in sorted {
            let diff = abs(item - value)
            let closestDiff = abs(closest - value)
            if diff < closestDiff {
                closest = item
            }
        }
        return closest
    }
    
    init() {
        let config = ConfigReader.load()
        _cols = State(initialValue: config.cols)
        _rows = State(initialValue: config.rows)
        _cellStyle = State(initialValue: config.cellStyle)
        _hotkeyString = State(initialValue: SettingsView.hotkeyStringFrom(config.hotkey))
        _socketHealthInterval = State(initialValue: nearest(to: config.socketHealthInterval, from: socketHealthOptions))
        _uiScale = State(initialValue: nearest(to: config.uiScale, from: uiScaleSteps))
        _autoHideTimeout = State(initialValue: config.autoHideTimeout)
        _theme = State(initialValue: config.theme)
        _showMode = State(initialValue: config.showMode)
        _maxSpaces = State(initialValue: config.maxSpaces)
        _backgroundAlpha = State(initialValue: nearest(to: config.backgroundAlpha, from: backgroundTransparencySteps))
        _mode = State(initialValue: config.mode)
        _iconScale = State(initialValue: nearest(to: config.iconScale, from: iconScaleSteps))
        _showNames = State(initialValue: config.showNames)
    }
    
private func saveConfig() {
    let showNamesStr = showNames ? "true" : "false"
    let launchAtLogin = SMAppService.mainApp.status == .enabled
    
    // Preserve existing AUTO_HIDE_TIMEOUT from file if present and valid
    var autoHideTimeout = self.autoHideTimeout
    if let existing = try? String(contentsOfFile: configPath, encoding: .utf8) {
        for line in existing.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("AUTO_HIDE_TIMEOUT=") else { continue }
            let raw = trimmed.dropFirst("AUTO_HIDE_TIMEOUT=".count)
            let cleaned = String(raw).trimmingCharacters(in: .whitespacesAndNewlines)
            if let commentIdx = cleaned.firstIndex(of: "#") {
                let val = cleaned[..<commentIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                if let v = Int(val), v >= 0 { autoHideTimeout = v }
            } else {
                if let v = Int(cleaned), v >= 0 { autoHideTimeout = v }
            }
        }
    }
    
    let lines = [
        "GRID_COLS=\(cols)",
        "GRID_ROWS=\(rows)",
        "CELL_STYLE=\(cellStyleString)",
        "HOTKEY=\(hotkeyString)",
        "SOCKET_HEALTH_INTERVAL=\(socketHealthInterval)",
        "UI_SCALE=\(uiScale)",
        "AUTO_HIDE_TIMEOUT=\(autoHideTimeout)",
        "THEME=\(theme)",
        "SHOW_MODE=\(showModeString)",
        "MAX_SPACES=\(maxSpaces)",
        "BACKGROUND_ALPHA=\(backgroundAlpha)",
        "MODE=\(modeString)",
        "ICON_SCALE=\(iconScale)",
        "SHOW_NAMES=\(showNamesStr)",
        "LAUNCH_AT_LOGIN=\(launchAtLogin ? "true" : "false")"
    ]
    let content = lines.joined(separator: "\n")
    do {
        try content.write(toFile: configPath, atomically: true, encoding: .utf8)
        // Notify any open HUD to reload config
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    } catch {
        print("Failed to write config: \(error)")
    }
}

    var body: some View {
        Form {
            Section(header: Text("Grid")) {
                HStack {
                    Stepper("Columns: \(cols)", value: $cols, in: 1...20)
                        .onChange(of: cols) { _ in saveConfig() }
                    Stepper("Rows: \(rows)", value: $rows, in: 1...10)
                        .onChange(of: rows) { _ in saveConfig() }
                }
                Picker("Cell Style", selection: $cellStyle) {
                    Text("Rectangles").tag(CellStyle.rects)
                    Text("Icons").tag(CellStyle.icons)
                    Text("Hybrid").tag(CellStyle.hybrid)
                }
                .onChange(of: cellStyle) { _ in saveConfig() }
                Picker("Show Mode", selection: $showMode) {
                    Text("All Spaces").tag(ShowMode.all)
                    Text("Active Spaces").tag(ShowMode.active)
                }
                .onChange(of: showMode) { _ in saveConfig() }
                Picker("Max Spaces", selection: $maxSpaces) {
                    ForEach(maxSpacesOptions, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .onChange(of: maxSpaces) { _ in saveConfig() }
                Toggle("Show Space Numbers", isOn: $showNames)
                    .onChange(of: showNames) { _ in saveConfig() }
            }

Section(header: Text("Appearance")) {
                 Picker("Theme", selection: $theme) {
                     Text("Default").tag("default")
                     Text("Tokyo Night").tag("tokyonight")
                     Text("Catppuccin").tag("catppuccin")
                     Text("Monokai Dark").tag("monokai-dark")
                     Text("Monokai Light").tag("monokai-light")
                     Text("Dracula").tag("dracula")
                     Text("AYU").tag("ayu")
                     Text("GitHub").tag("github")
                     Text("VS Code").tag("vscode")
                     Text("Xcode").tag("xcode")
                     Text("Nord").tag("nord")
                     Text("Atom One Dark").tag("atom-one-dark")
                 }
                 .onChange(of: theme) { _ in saveConfig() }
                 Picker("Background Color", selection: $mode) {
                     Text("Light").tag(ThemeMode.light)
                     Text("Dark").tag(ThemeMode.dark)
                     Text("Auto").tag(ThemeMode.auto)
                 }
                 .onChange(of: mode) { _ in saveConfig() }
VStack(alignment: .leading) {
                    Text("Background Transparency")
                    CustomStepper(steps: backgroundTransparencySteps, value: $backgroundAlpha)
                        .onChange(of: backgroundAlpha) { _ in saveConfig() }
                }
                 VStack(alignment: .leading) {
                     Text("Icon Scale")
                     CustomStepper(steps: iconScaleSteps, value: $iconScale)
                         .onChange(of: iconScale) { _ in saveConfig() }
                 }
                 VStack(alignment: .leading) {
                     Text("UI Scale")
                     CustomStepper(steps: uiScaleSteps, value: $uiScale)
                         .onChange(of: uiScale) { _ in saveConfig() }
                 }
             }

            Section(header: Text("Behavior")) {
                HotkeyRecorder(label: "Hotkey", hotkey: $hotkeyString)
                    .onChange(of: hotkeyString) { _ in saveConfig() }
                Picker("Socket Health Interval (s)", selection: $socketHealthInterval) {
                    ForEach(socketHealthOptions, id: \.self) { v in
                        Text("\(v)").tag(v as Int)
                    }
                }
                .onChange(of: socketHealthInterval) { _ in saveConfig() }
                Stepper("Auto-hide Timeout (s): \(autoHideTimeout)", value: $autoHideTimeout, in: 0...60)
                    .onChange(of: autoHideTimeout) { _ in saveConfig() }
            }

            Section {
                Button("Open Config Folder") {
                    openConfigFolder()
                }
            }
        }
        .frame(width: 450, height: 650)
        .onAppear {
            let config = ConfigReader.load()
            cols = config.cols
            rows = config.rows
            cellStyle = config.cellStyle
            hotkeyString = SettingsView.hotkeyStringFrom(config.hotkey)
            socketHealthInterval = nearest(to: config.socketHealthInterval, from: socketHealthOptions)
            uiScale = nearest(to: config.uiScale, from: uiScaleSteps)
            autoHideTimeout = config.autoHideTimeout
            theme = config.theme
            showMode = config.showMode
            maxSpaces = config.maxSpaces
            backgroundAlpha = nearest(to: config.backgroundAlpha, from: backgroundTransparencySteps)
            mode = config.mode
            iconScale = nearest(to: config.iconScale, from: iconScaleSteps)
            showNames = config.showNames
        }
    }
        let url = URL(fileURLWithPath: NSString(string: "~/.config/spacemap").expandingTildeInPath)
    
    private func openConfigFolder() {
        let url = URL(fileURLWithPath: NSString(string: "~/.config/spacemap").expandingTildeInPath)
        NSWorkspace.shared.open(url)
    }
    private var cellStyleString: String {
        switch cellStyle {
        case .rects: return "rects"
        case .icons: return "icons"
        case .hybrid: return "hybrid"
        }
    }
    
    private var showModeString: String {
        switch showMode {
        case .all: return "all"
        case .active: return "active"
        }
    }
    
    private var modeString: String {
        switch mode {
        case .light: return "light"
        case .dark: return "dark"
        case .auto: return "auto"
        }
    }
    
    static func hotkeyStringFrom(_ hotkey: HotkeyConfig) -> String {
        var parts: [String] = []
        if hotkey.modifiers.contains(.maskControl) { parts.append("ctrl") }
        if hotkey.modifiers.contains(.maskCommand) { parts.append("cmd") }
        if hotkey.modifiers.contains(.maskAlternate) { parts.append("alt") }
        if hotkey.modifiers.contains(.maskShift) { parts.append("shift") }
        
        let keyString: String
        switch hotkey.keyCode {
        case 49: keyString = "space"
        case 48: keyString = "tab"
        case 36: keyString = "return"
        case 53: keyString = "escape"
        case 51: keyString = "delete"
        case 121: keyString = "pgdn"
        case 116: keyString = "pgup"
        case 115: keyString = "home"
        case 119: keyString = "end"
        case 123: keyString = "left"
        case 124: keyString = "right"
        case 125: keyString = "down"
        case 126: keyString = "up"
        case 122: keyString = "f1"
        case 120: keyString = "f2"
        case 99:  keyString = "f3"
        case 118: keyString = "f4"
        case 96:  keyString = "f5"
        case 97:  keyString = "f6"
        case 98:  keyString = "f7"
        case 100: keyString = "f8"
        case 101: keyString = "f9"
        case 109: keyString = "f10"
        case 103: keyString = "f11"
        case 111: keyString = "f12"
        default:
            keyString = "\(hotkey.keyCode)"
        }
        parts.append(keyString)
        return parts.joined(separator: "+")
    }
}

// NOTE: CellStyle, ShowMode, ThemeMode, HotkeyConfig imported from Models.swift

struct CustomStepper: View {
    let steps: [Double]
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Button(action: { stepDown() }) {
                Image(systemName: "minus.circle")
            }
            .disabled(currentIndex == 0)
            
            Slider(value: Binding(
                get: { Double(currentIndex) },
                set: { newIndex in
                    let idx = max(0, min(steps.count - 1, Int(newIndex.rounded())))
                    value = steps[idx]
                }
            ), in: 0...Double(steps.count - 1), step: 1)
            
            Button(action: { stepUp() }) {
                Image(systemName: "plus.circle")
            }
            .disabled(currentIndex == steps.count - 1)
        }
    }
    
    private var currentIndex: Int {
        steps.firstIndex(of: value) ?? 0
    }
    
    private func stepDown() {
        if currentIndex > 0 {
            value = steps[currentIndex - 1]
        }
    }
    
    private func stepUp() {
        if currentIndex < steps.count - 1 {
            value = steps[currentIndex + 1]
        }
    }
}

// MARK: - HotkeyRecorder

struct HotkeyRecorder: View {
    let label: String
    @Binding var hotkey: String
    @State private var isRecording = false
    @State private var monitor: Any?
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button(isRecording ? "Recording..." : hotkey.isEmpty ? "Click to record" : hotkey) {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .keyboardShortcut(.defaultAction)
        }
    }
    
    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            guard isRecording else { return }
            
            var parts: [String] = []
            let flags = event.modifierFlags
            if flags.contains(.control) { parts.append("ctrl") }
            if flags.contains(.command) { parts.append("cmd") }
            if flags.contains(.option) { parts.append("alt") }
            if flags.contains(.shift) { parts.append("shift") }
            
            let keyString: String
            switch Int(event.keyCode) {
            case 49: keyString = "space"
            case 48: keyString = "tab"
            case 36: keyString = "return"
            case 53: keyString = "escape"
            case 51: keyString = "delete"
            case 76: keyString = "delete"
            case 121: keyString = "pgdn"
            case 116: keyString = "pgup"
            case 115: keyString = "home"
            case 119: keyString = "end"
            case 123: keyString = "left"
            case 124: keyString = "right"
            case 125: keyString = "down"
            case 126: keyString = "up"
            case 122: keyString = "f1"
            case 120: keyString = "f2"
            case 99:  keyString = "f3"
            case 118: keyString = "f4"
            case 96:  keyString = "f5"
            case 97:  keyString = "f6"
            case 98:  keyString = "f7"
            case 100: keyString = "f8"
            case 101: keyString = "f9"
            case 109: keyString = "f10"
            case 103: keyString = "f11"
            case 111: keyString = "f12"
            default:
                if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                    keyString = String(chars.lowercased().first!)
                } else {
                    keyString = "\(event.keyCode)"
                }
            }
            
            parts.append(keyString)
            let recorded = parts.joined(separator: "+")
            
            DispatchQueue.main.async {
                hotkey = recorded
                stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}
