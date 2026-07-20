# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-01-19

### Added
- Space naming system with dynamic configuration in settings window
- Settings window with scrollable, resizable UI
- Hotkey recorder with global keyboard capture
- Launch at login toggle with state indicator
- Config file self-healing (auto-generates missing keys)
- CLI options: `--version`, `--help`, `--config`, `--trigger`, `--show-menu`, `--settings`
- Live auto-hide timeout with configurable delay
- Hotkey rapid-press protection (`isToggling` guard)
- Symlink creation (`/usr/local/bin/spacemap`) at launch
- Active space live highlighting via polling

### Changed
- Settings window now scrollable with proper dimensions
- `ThemeMode.automatic` renamed to `.auto` for consistency
- Config serialization uses string names instead of rawValue numbers
- Cell styles (rects, icons, hybrid) now properly serialized
- Auto-hide timer now resets unconditionally on HUD show
- Config parser now handles BOM, CR/LF, and inline comments

### Fixed
- HUD staying visible during space changes
- Hotkey double-trigger on rapid presses
- Settings window opening at full size
- Auto-hide timeout not syncing after settings changes
- Space names UI text field focus preservation
- Yabai not running alert not appearing frontmost
- Spaces MRU warning not appearing on startup
- Window drag-and-drop coordinate system mismatch

---

## [0.2.0] - 2024-03-15

### Added
- Menubar status item for manual show/hide
- Configurable hotkey (default: Ctrl+Page Down)
- Video demo in README
- Homebrew cask distribution support

### Changed
- Updated README with installation instructions
- Improved hotkey configuration flow

---

## [0.1.0] - 2023-06-01

### Added
- Homebrew distribution via `jsheffie/tap`
- Initial public release
- Basic UI scaling support

### Changed
- Repository moved to `jsheffie/spacemap`

---

## [0.0.8] - 2023-03-20

### Added
- Improved README install instructions

### Changed
- Documentation updates

---

## [0.0.7] - 2023-02-15

### Added
- Hybrid cell style (rectangles + app icons)
- Enhanced README documentation

---

## [0.0.6] - 2023-01-20

### Added
- Click-to-change-workspace functionality

---

## [0.0.5] - 2023-01-10

### Added
- Background color and highlight fixes
- Reverted CELL_STYLE config (subsequent fix in 0.0.4)

### Fixed
- Cell visibility and highlight in icons mode
- Background color rendering

---

## [0.0.4] - 2022-12-15

### Added
- CELL_STYLE config option (rects vs icons)
- Icons support with hybrid mode

### Changed
- Cell rendering logic

---

## [0.0.3] - 2022-12-01

### Fixed
- Active cell highlight visibility behind window rects
- Colored outline contrast

---

## [0.0.2] - 2022-11-15

### Added
- Event-driven architecture with yabai signals
- Auto-hide timer reset on space change

### Fixed
- HUD getting stuck on a workspace

---

## [0.0.1] - 2022-11-01

### Added
- Initial commit
- Basic HUD grid overlay
- yabai workspace visualization
- App adaptation from existing sharing (github/intellij-plantuml-plugin)
