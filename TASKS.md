# spacemap Roadmap

A living list of planned features, known bugs, and future improvements for the project. Items are categorized by priority and status.

## ✅ Completed

- **CLI Options**: `--version`, `--help`, `--config`, `--trigger`, `--show-menu`, `--settings`
- **Settings Window**: Full settings UI with live-save, space name editor, hotkey recorder
- **Hotkey Rapid-Press Fix**: `isToggling` guard in `HUDWindowController`
- **Symlink Creation**: Automated `/usr/local/bin/spacemap` symlink at launch via `ensureSymlink()`
- **HUD Active Space Highlighting**: Live refresh timer calls `refreshState` for active space highlighting
- **Launch at Login**: Toggle with state indicator and first-launch prompt
- **Show Space Numbers Toggle**: Per-cell space number display
- **Show Space Names Toggle**: Per-cell custom name display
- **Show Icon Strip Toggle**: Per-cell app icon strip at bottom
- **Hide Menu Bar Icon Toggle**: Run headless, use hotkey or CLI
- **Move to Applications Prompt**: First-launch prompt to move app to /Applications
- **Config File Self-Heal**: Auto-generates on first launch, self-heals missing keys, handles BOM/CR/LF
- **Auto-Hide Timeout Fix**: Fixed HUD not hiding and hotkey double-trigger
- **Yabai Mandatory Check**: Prevents launch if yabai is not running; shows critical alert
- **MRU Spaces Detection**: Warns user and offers to disable macOS MRU spaces
- **Accessibility Permission Request**: Polls every 2s until granted, registers hotkey automatically
- **Cell Opacity / Inactive Dimming**: Inactive spaces dimmed in the grid
- **Window Previews / Thumbnails**: ScreenCaptureKit-based per-space thumbnail capture (experimental)
- **App Icon**: Bundled `.icns` file for macOS app bundle
- **Space Naming System**: Config-based `SPACE_NAMES=1:Name,2:Name` with settings UI editor
- **Menubar Improvements**: Hotkey symbols shown, Cmd+R restart, Screen Recording permissions link
- **Config Validation**: Validates keys/values on load, logs warnings for invalid entries
- **DMG Assets**: DMG installer with /Applications symlink
- **HUD Pinning**: Implemented via `AUTO_HIDE_TIMEOUT=0` (never auto-hide)

## 🚀 High Priority

### Features

| Task | Description | Status |
|------|-------------|--------|
| **Icon Caching** | Cache app icons via `IconCache` singleton to avoid re-fetching on every render | ✅ Done |
| **Dynamic yabai Path** | Auto-detect yabai location (`/opt/homebrew/bin/yabai` or `/usr/local/bin/yabai`) for Intel Mac support | 🔄 Planned |

### Bug Fixes

| Task | Description | Status |
|------|-------------|--------|
| **Drag-and-Drop Ambiguity** | Falls back to click proximity for multi-window apps | 🔄 Open |
| **Icon Strip Flicker** | Re-fetching icons via `NSWorkspace` causes flicker on space change | ✅ Fixed (IconCache) |
| **Hotkey Limited Key Support** | Missing support for F13-F20/media keys in config parser | 🔄 Open |

---

## 🛠 Medium Priority

### Features

| Task | Description | Status |
|------|-------------|--------|
| **Theme Files (.smthemes)** | Expose themes as editable files in `~/.config/spacemap/themes/`. Default greyscale theme, import/export | 🔄 Planned |
| **Drag-to-Swap** | Swap windows between spaces via drag-and-drop within the HUD | 🔄 Planned |
| **Custom Cell Colors** | Allow per-space/app custom colors in config | 🔄 Planned |
| **Grid Gap/Padding Customization** | Add config options for spacing between cells | 🔄 Planned |
| **Multi-Monitor Awareness** | Show workspaces per display in HUD | 🔄 Planned |

### Performance

| Task | Description | Status |
|------|-------------|--------|
| **CPU/Memory Optimization** | Profile and reduce resource usage, especially in background | 🔄 Planned |
| **Reduced SwiftUI Rerenders** | Optimize HUD recreations during drag-and-drop | 🔄 Planned |

---

## 🌌 Low Priority

### Features

| Task | Description | Status |
|------|-------------|--------|
| **i18n Localization** | Spanish, German, Italian, French, and other major languages | 🔄 Planned |
| **Hotkey Conflicts UI** | Show menubar conflicts with other apps | 🔄 Planned |
| **Keyboard Navigation** | Arrow-key and vim-key navigation within HUD (currently handled via skhd) | 🔄 Planned |

### Integration

| Task | Description | Status |
|------|-------------|--------|
| **Native Spaces Support** | Drop yabai dependency for native macOS Spaces | 🔄 Planned |
| **Other WM Support** | Add support for aerospace/rectangle/etc. | 🔄 Planned |

### Build & CI

| Task | Description | Status |
|------|-------------|--------|
| **Unit Tests** | Add XCTest for ConfigReader, YabaiClient, scaling logic | 🔄 Planned |
| **GitHub Actions / CI** | Automated build, test, and release pipeline | 🔄 Planned |
| **Homebrew Formula Updates** | Update tap for better Intel/homebrew paths | 🔄 Planned |

---

## 🐛 Known Bugs

| Bug | Description | Status |
|-----|-------------|--------|
| **Config Corruption** | Corrupt config overrides all settings with defaults | 🔄 Open |

---

## 🧪 Experimental Ideas

| Idea | Description | Status |
|------|-------------|--------|
| **HUD Pinning** | Separate hotkey for temporary (timed) vs permanent HUD display | 💡 Concept |
| **Window Rules** | Move windows between spaces via regex matches | 💡 Concept |
| **Space Templates** | Predefined app layouts for quick setup | 💡 Concept |
