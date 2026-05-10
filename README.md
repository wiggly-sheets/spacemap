# spacemap

A native macOS HUD that shows your yabai workspace grid on demand. Press Ctrl+Space to toggle a floating overlay showing all your desktops as a 2D grid with window positions highlighted inside each cell.

```
┌────┬────┬────┬────┬────┬────┬────┬────┐
│ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │  ← top row
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 9  │ 10 │ 11 │ 12 │ 13 │ 14 │ 15 │ 16 │  ← bottom row
└────┴────┴────┴────┴────┴────┴────┴────┘
         ↑ active desktop highlighted in blue
```

Window positions are drawn as colored rectangles inside each cell (one color per app, derived from app name). The HUD refreshes every 200ms while open so the active cell updates as you switch desktops.

## Requirements

- macOS 13+
- [yabai](https://github.com/koekeishiya/yabai) installed at `/opt/homebrew/bin/yabai` and running
- Xcode Command Line Tools (`xcode-select --install`)
- Accessibility permission (prompted on first launch)

## Install

```bash
# 1. Create config (sets grid dimensions)
make config

# 2. Build and install
make run
```

On first launch macOS will prompt for Accessibility permission. Grant it — spacemap needs it to monitor the global Ctrl+Space hotkey.

## Config

Grid dimensions are read from `~/.config/spacemap/config` on every HUD open (no restart needed after editing):

```bash
GRID_COLS=8
GRID_ROWS=2
```

Change these to match your yabai space layout. A 4×4 grid would be `GRID_COLS=4` / `GRID_ROWS=4`.

## Usage

| Action | Result |
|--------|--------|
| `Ctrl+Space` | Toggle HUD open/closed |
| Switch desktops while HUD is open | Active cell updates live |

## Makefile targets

| Target | Description |
|--------|-------------|
| `make run` | Build, install, and launch |
| `make dev` | Rebuild and relaunch during development (see note below) |
| `make config` | Create default config file if missing |
| `make permissions` | Print instructions for fixing a broken hotkey |
| `make uninstall` | Kill app and remove from /Applications |
| `make clean` | Remove build artifacts |

## Developer notes

### Always launch via `open`, never run the binary directly

```bash
# CORRECT
open /Applications/spacemap.app
make run

# WRONG — AXIsProcessTrusted() returns false, hotkey won't work
/Applications/spacemap.app/Contents/MacOS/spacemap
```

macOS grants Accessibility permission to the `.app` bundle as a whole, not the raw binary. Running the binary directly bypasses the bundle context and the permission check fails silently.

### Accessibility permission is revoked on every reinstall

Every time you rebuild and reinstall, macOS revokes the Accessibility permission because the binary hash changes. After running `make dev`, you must re-grant permission:

1. Go to **System Settings → Privacy & Security → Accessibility**
2. Click **−** to remove `spacemap`
3. The app will prompt for permission again — grant it

`make permissions` prints this reminder.

### The permission flow

On launch, spacemap calls `AXIsProcessTrustedWithOptions(prompt: true)` if not trusted, which opens System Settings to the Accessibility page. After you toggle it on, the app polls every second and registers the hotkey automatically — no restart needed.

### Project structure

```
spacemap/
├── Package.swift
├── Sources/spacemap/
│   ├── App.swift                 # NSApplicationMain entry point
│   ├── HUDWindowController.swift # NSPanel lifecycle + refresh timer
│   ├── GridView.swift            # SwiftUI 8×2 grid layout
│   ├── CellView.swift            # Single desktop cell with window rects
│   ├── YabaiClient.swift         # yabai JSON queries
│   ├── ConfigReader.swift        # ~/.config/spacemap/config parser
│   ├── Models.swift              # YabaiSpace, YabaiWindow, GridConfig
│   ├── HotkeyMonitor.swift       # CGEventTap for Ctrl+Space
│   └── Info.plist
└── Makefile
```
