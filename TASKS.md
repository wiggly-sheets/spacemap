# spacemap Roadmap

A living list of planned features, known bugs, and future improvements for the project. Items are categorized by priority and status.

## 🚀 High Priority

### Features

| Task | Description | Status |
|------|-------------|--------|
| **App Icon** | Generate and bundle a proper `.icns` file for macOS app bundle. | 🟡 In Progress |
| **yabai Mandatory Check** | Prevent app launch if yabai is not running. Show critical alert dialog. | ✅ Done |
| **Space Naming System** | Show space names (from config) in cells instead of just numbers. Support menubar editor. | 🟡 In Progress |
| **Accessibility Permission Request** | Replace System Preferences link with direct permission request and polling. | ✅ Done |
| **Settings Window** | Add a settings window with space name editor and config file reloader. | 🔄 Planned |
| **Config Validation** | Validate config keys/values on load and log warnings for invalid entries. | 🔄 Planned |

### Bug Fixes

| Task | Description | Status |
|------|-------------|--------|
| **HUD Stuck Bug** | Fixed auto-hide being extended by `space_changed` signals. | ✅ Done |
| **Config Comment Parsing** | Fixed config loader failing on inline `# comments`. | ✅ Done |
| **UI Scaling** | Fixed `UI_SCALE` acting as 10× multiplier (0.1-1.0 → 1×-10× scale). | ✅ Done |
| **Permissions Revocation** | Handle Accessibility revocation on reinstall by prompting user. | ✅ Done |

---

## 🛠 Medium Priority

### Features

| Task | Description | Status |
|------|-------------|--------|
| **Custom Cell Colors** | Allow per-space/app custom colors in config. | 🔄 Planned |
| **Grid Gap/Padding Customization** | Add config options for spacing between cells. | 🔄 Planned |
| **Multi-Monitor Awareness** | Show workspaces per display in HUD. | 🔄 Planned |
| **Window Previews** | Replace rectangles with window thumbnails. | 🔄 Planned |
| **Drag-and-Drop Reliability** | Improve window drag detection for multi-window apps. | 🔄 Planned |
| **Keyboard Navigation** | Add arrow-key navigation within HUD. | 🔄 Planned |

### Performance

| Task | Description | Status |
|------|-------------|--------|
| **Icon Caching** | Cache app icons to avoid re-fetching on every render. | 🔄 Planned |
| **Reduced SwiftUI Rerenders** | Optimize HUD recreations during drag-and-drop. | 🔄 Planned |

---

## 🌌 Low Priority

### Features

| Task | Description | Status |
|------|-------------|--------|
| **Annotations** | Let users draw notes/labels on the HUD. | 🔄 Planned |
| **Hotkey Conflicts UI** | Show menubar conflicts with other apps. | 🔄 Planned |
| **Theme Editor UI** | Interactive theme editor in settings window. | 🔄 Planned |
| **i18n Localization** | Add non-English language support. | 🔄 Planned |

### Integration

| Task | Description | Status |
|------|-------------|--------|
| **Native Spaces Support** | Drop yabai dependency for native macOS Spaces. | 🔄 Planned |
| **Other WM Support** | Add support for aerospace/rectangle/etc. | 🔄 Planned |
| **CLI Interface** | Add command-line interface for scripting. | 🔄 Planned |

---

## 🐛 Known Bugs

| Bug | Description | Status |
|-----|-------------|--------|
| **Drag-and-Drop Ambiguity** | Falls back to click proximity for multi-window apps. | 🔄 Open |
| **Icon Strip Flicker** | Re-fetching icons via `NSWorkspace` causes flicker on space change. | 🔄 Open |
| **Config Corruption** | Corrupt config overrides all settings with defaults. | 🔄 Open |
| **Hotkey Limited Key Support** | Missing support for F13-F20/media keys in config parser. | 🔄 Open |
| **yabai Intel Path** | Hardcoded `/opt/homebrew` breaks Intel Macs (`/usr/local`). | 🔄 Open |

---

## 📦 Build & Testing

| Task | Description | Status |
|------|-------------|--------|
| **Unit Tests** | Add XCTest for ConfigReader, YabaiClient, scaling logic. | 🔄 Planned |
| **GitHub Actions** | Add CI pipeline for macOS builds/tests. | 🔄 Planned |
| **Homebrew Formula Updates** | Update tap for better Intel/homebrew paths. | 🔄 Planned |
| **DMG Styling** | Improve DMG background/assets. | 🔄 Planned |

---

## 🧪 Experimental Ideas

| Idea | Description | Status |
|------|-------------|--------|
| **Window Rules** | Move windows between spaces via regex matches. | 💡 Concept |
| **Space Templates** | Predefined app layouts for quick setup. | 💡 Concept |
| **HUD Pinning** | Option to pin HUD on-screen permanently. | 💡 Concept |
| **Cell Opacity** | Dim inactive spaces. | 💡 Concept |
| **Drag-to-Swap** | Swap windows/spaces via drag. | 💡 Concept |