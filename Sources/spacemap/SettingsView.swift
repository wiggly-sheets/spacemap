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
    @State private var autoHideTimeout: Int = 5
    @State private var theme: String = "default"
    @State private var showMode: ShowMode = .all
    @State private var maxSpaces: Int = 16
    @State private var backgroundAlpha: Double = 0.3
    @State private var mode: ThemeMode = .automatic
    @State private var iconScale: Double = 1.0
    @State private var showNames: Bool = true
    
    private let socketHealthOptions = [15, 30, 45, 60]
    
    private let configPath = NSString(string: "~/.config/spacemap/config").expandingTildeInPath
    
    private var maxSpacesOptions: [Int] { Array(1...16) }
    
    private var backgroundAlphaSteps: [Double] {
        (0...20).map { Double($0) / 20.0 } // 0.0, 0.05, 0.10, ..., 1.0
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
        _cellStyle = State(initialValue: cellStyle)
        _hotkeyString = State(initialValue: SettingsView.hotkeyStringFrom(config.hotkey))
        _socketHealthInterval = State(initialValue: nearest(to: config.socketHealthInterval, from: socketHealthOptions))
        _uiScale = State(initialValue: nearest(to: config.uiScale, from: uiScaleSteps))
        _autoHideTimeout = State(initialValue: config.autoHideTimeout)
        _theme = State(initialValue: config.theme)
        _showMode = State(initialValue: showMode)
        _maxSpaces = State(initialValue: maxSpaces)
        _backgroundAlpha = State(initialValue: nearest(to: config.backgroundAlpha, from: backgroundAlphaSteps))
        _mode = State(initialValue: mode)
        _iconScale = State(initialValue: nearest(to: iconScale, from: iconScaleSteps))
        _showNames = State(initialValue: showNames)
    }
    
private func saveConfig() {
    let showNamesStr = showNames ? "true" : "false"
    let launchAtLogin = SMAppService.mainApp.status == .enabled
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
                Picker("Mode", selection: $mode) {
                    Text("Light").tag(ThemeMode.light)
                    Text("Dark").tag(ThemeMode.dark)
                    Text("Auto").tag(ThemeMode.automatic)
                }
                .onChange(of: mode) { _ in saveConfig() }
                VStack(alignment: .leading) {
                    Text("Background Alpha")
                    Slider(value: $backgroundAlpha, in: 0...1, step: 0.05)
                        .onChange(of: backgroundAlpha) { _ in saveConfig() }
                }
                VStack(alignment: .leading) {
                    Text("Icon Scale")
                    Slider(value: $iconScale, in: 0.5...2.0, step: 0.05)
                        .onChange(of: iconScale) { _ in saveConfig() }
                }
                VStack(alignment: .leading) {
                    Text("UI Scale")
                    Slider(value: $uiScale, in: 0.1...3.0, step: 0.05)
                        .onChange(of: uiScale) { _ in saveConfig() }
                }
            }

            Section(header: Text("Behavior")) {
                TextField("Hotkey", text: $hotkeyString)
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
        case .automatic: return "auto"
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

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}
