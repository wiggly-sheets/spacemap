import Foundation
import CoreGraphics

enum CellStyle: Int, CaseIterable, Identifiable {
    case rects, icons, thumbnails
    var id: Int { rawValue }
}
enum ShowMode: String, CaseIterable, Identifiable { case all, active; var id: String { rawValue } }
enum ThemeMode: String, CaseIterable, Identifiable { case light, dark, auto; var id: String { rawValue } }

struct HotkeyConfig {
    var keyCode: CGKeyCode
    var modifiers: CGEventFlags

    // Default: Ctrl+Page Down
    static let `default` = HotkeyConfig(keyCode: 121, modifiers: .maskControl)
}

struct GridConfig {
    var cols: Int
    var rows: Int
    var cellStyle: CellStyle
    var hotkey: HotkeyConfig
    var socketHealthInterval: Int
    var uiScale: Double // 0.1 to 1.0
    var autoHideTimeout: Int // seconds
    var theme: String // "default", "tokyonight", etc.
    var showMode: ShowMode // "all" or "active"
    var maxSpaces: Int // 1-16, default 16
    var backgroundAlpha: Double // 0.0 to 1.0, 0=transparent 1=opaque
    var mode: ThemeMode // light, dark, or auto (follow system)
    var iconScale: Double // 0.5 to 2.0, app icon size multiplier
    var showSpaceNumbers: Bool // show space index numbers in cells
    var showSpaceNames: Bool // show configured space name text in cells
    var showIconStrip: Bool // show icon strip at the bottom of each cell
    var showMultiAppIcons: Bool // show one icon per window (true) or one per unique app (false)
    var hideMenuBarIcon: Bool // hide the menu bar icon (settings accessible via re-launch or Cmd+, in HUD)
    var spaceNames: [Int: String] // space id to name mapping
    var useVimKeys: Bool // navigate spaces with hjkl when HUD is visible
    var useArrowKeys: Bool // navigate spaces with arrow keys when HUD is visible

    static let `default` = GridConfig(cols: 8, rows: 2, cellStyle: .rects, hotkey: .default, socketHealthInterval: 60, uiScale: 1.0, autoHideTimeout: 5, theme: "default", showMode: .all, maxSpaces: 16, backgroundAlpha: 0.3, mode: .auto, iconScale: 1.0, showSpaceNumbers: true, showSpaceNames: true, showIconStrip: true, showMultiAppIcons: false, hideMenuBarIcon: false, spaceNames: [:], useVimKeys: false, useArrowKeys: false)
}

struct AppTheme {
    let background: UInt32      // HUD grid background
    let focused: UInt32         // Focused space border/highlight
    let text: UInt32            // Text color
    let dropTarget: UInt32      // Drop target highlight
    let cellBg: UInt32          // Unfocused cell fill
    let cellBgFocused: UInt32   // Focused cell fill

    static let `default` = AppTheme(
        background: 0x000000, focused: 0x4a9eff, text: 0xffffff,
        dropTarget: 0x00ff00, cellBg: 0x000000, cellBgFocused: 0x4a9eff
    )
    static let tokyonight = AppTheme(
        background: 0x1a1b26, focused: 0x7aa2f7, text: 0xa9b1d6,
        dropTarget: 0xbb9af7, cellBg: 0x1a1b26, cellBgFocused: 0x1a1b26
    )
    static let catppuccin = AppTheme(
        background: 0x1e1e2e, focused: 0xcba6f7, text: 0xcdd6f4,
        dropTarget: 0xf5c2e7, cellBg: 0x313244, cellBgFocused: 0x45475a
    )
    static let monokaiDark = AppTheme(
        background: 0x272822, focused: 0xa6e22e, text: 0xf8f8f2,
        dropTarget: 0xfd971f, cellBg: 0x3e3d32, cellBgFocused: 0x49483e
    )
    static let monokaiLight = AppTheme(
        background: 0xfafafa, focused: 0xa6e22e, text: 0x272822,
        dropTarget: 0xfd971f, cellBg: 0xe8e8d8, cellBgFocused: 0xd6d6c8
    )
    static let dracula = AppTheme(
        background: 0x282a36, focused: 0xbd93f9, text: 0xf8f8f2,
        dropTarget: 0xff79c6, cellBg: 0x44475a, cellBgFocused: 0x565a79
    )
    static let ayu = AppTheme(
        background: 0x0b0e14, focused: 0xff8f40, text: 0xbfbdb6,
        dropTarget: 0xf07178, cellBg: 0x1a1f29, cellBgFocused: 0x2a3140
    )
    static let github = AppTheme(
        background: 0x0d1117, focused: 0x3fb950, text: 0xc9d1d9,
        dropTarget: 0x58a6ff, cellBg: 0x161b22, cellBgFocused: 0x21262d
    )
    static let vscode = AppTheme(
        background: 0x1e1e1e, focused: 0x007acc, text: 0xcccccc,
        dropTarget: 0x4ec9b0, cellBg: 0x252526, cellBgFocused: 0x333333
    )
    static let xcode = AppTheme(
        background: 0x1f1f24, focused: 0x5e9eff, text: 0xffffff,
        dropTarget: 0x6c5ce7, cellBg: 0x2c2c32, cellBgFocused: 0x3a3a42
    )
    static let nord = AppTheme(
        background: 0x2e3440, focused: 0x88c0d0, text: 0xd8dee9,
        dropTarget: 0x81a1c1, cellBg: 0x3b4252, cellBgFocused: 0x434c5e
    )
    static let atomOneDark = AppTheme(
        background: 0x282c34, focused: 0x61afef, text: 0xabb2bf,
        dropTarget: 0x98c379, cellBg: 0x2c323c, cellBgFocused: 0x3a404a
    )

    static func named(_ name: String) -> AppTheme {
        switch name.lowercased() {
        case "tokyonight":    return .tokyonight
        case "catppuccin":    return .catppuccin
        case "monokai-dark", "monokai dark", "monokai": return .monokaiDark
        case "monokai-light", "monokai light": return .monokaiLight
        case "dracula":       return .dracula
        case "ayu":           return .ayu
        case "github":        return .github
        case "vscode":        return .vscode
        case "xcode":         return .xcode
        case "nord":          return .nord
        case "atom-one-dark", "atom one dark", "atom": return .atomOneDark
        default:              return .default
        }
    }
}

struct YabaiSpace: Decodable {
    let id: Int
    let index: Int
    let display: Int
    let hasFocus: Bool
    let label: String? // space name from yabai

    enum CodingKeys: String, CodingKey {
        case id, index, display
        case hasFocus = "has-focus"
        case label
    }
}

struct YabaiWindow: Decodable {
    let id: Int
    let app: String
    let space: Int
    let frame: WindowFrame
    let isHidden: Bool
    let isMinimized: Bool

    struct WindowFrame: Decodable {
        let x: CGFloat
        let y: CGFloat
        let w: CGFloat
        let h: CGFloat
    }

    enum CodingKeys: String, CodingKey {
        case id, app, space, frame
        case isHidden = "is-hidden"
        case isMinimized = "is-minimized"
    }

    var cgFrame: CGRect {
        CGRect(x: frame.x, y: frame.y, width: frame.w, height: frame.h)
    }
}

struct GridState: Equatable {

    let config: GridConfig
    let spaces: [YabaiSpace]
    let windows: [YabaiWindow]
    let displayBounds: CGRect
    let focusedIndex: Int?

    func windows(forSpace index: Int) -> [YabaiWindow] {
        return self.windows.filter { $0.space == index }
    }

    static func == (lhs: GridState, rhs: GridState) -> Bool {
        lhs.focusedIndex == rhs.focusedIndex
    }
}
