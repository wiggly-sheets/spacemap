# spacemap

A native macOS work`spacemap` that shows your yabai workspace grid on demand. Press Ctrl+Space to toggle a floating overlay showing all your desktops as a 2D grid with window positions highlighted inside each cell.

You do not have to disable System Integrity Protection to get this setup.

Example Configuration: 
```
┌────┬────┬────┬────┬────┬────┬────┬────┐
│ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │  ← top row
├────┼────┼────┼────┼────┼────┼────┼────┤
│ 9  │ 10 │ 11 │ 12 │ 13 │ 14 │ 15 │ 16 │  ← bottom row
└────┴────┴────┴────┴────┴────┴────┴────┘
         ↑ active desktop highlighted in blue
```
## Visualization

<img width="751" height="172" alt="Screenshot 2026-05-10 at 10 14 35 AM" src="https://github.com/user-attachments/assets/f7f2556a-9a1e-450e-bae4-2ad4268767cf" />


Window positions are drawn as colored rectangles inside each cell (one color per app, derived from app name). The active cell updates instantly as you switch desktops, driven by yabai's `space_changed` signal.

## Requirements

- macOS 13+
- [yabai](https://github.com/koekeishiya/yabai) installed at `/opt/homebrew/bin/yabai` and running
- Xcode Command Line Tools (`xcode-select --install`)
- Accessibility permission (prompted on first launch)
<img width="722" height="844" alt="Screenshot 2026-05-10 at 10 58 32 AM" src="https://github.com/user-attachments/assets/b6d90393-2100-44bc-ac6f-00fe1de66a98" />


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

### Cell styles

`CELL_STYLE` controls how windows are drawn inside each cell:

| Value | Description |
|-------|-------------|
| `rects` | Colored rectangles scaled from real window geometry (default) |
| `icons` | App icons positioned at each window's scaled location |

```bash
CELL_STYLE=rects   # default
CELL_STYLE=icons
```

**`CELL_STYLE=rects`**

<img width="752" height="476" alt="rects style" src="https://github.com/user-attachments/assets/1ee3e85c-12e4-4f34-a265-cb9f9fd69b56" />

**`CELL_STYLE=icons`**

<img width="718" height="464" alt="icons style" src="https://github.com/user-attachments/assets/5d35aa23-d5ef-4da1-8a74-df7278b43112" />

Run `make distconfig` to write a fresh config with `icons` active and `rects` commented out.

## Usage

| Action | Result |
|--------|--------|
| `Ctrl+Space` | Toggle HUD open/closed |
| Switch desktops while HUD is open | Active cell updates live |

## Makefile targets

| Target | Description |
|--------|-------------|
| `make run` | Build, install, and launch |
| `make dev1` | Uninstall; pause to remove Accessibility permission in System Settings |
| `make dev2` | Reinstall and relaunch; grant Accessibility permission when prompted |
| `make config` | Create default config file if missing |
| `make distconfig` | Overwrite config with defaults (`CELL_STYLE=icons`) |
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

Every time you rebuild and reinstall, macOS revokes the Accessibility permission because the binary hash changes. The two-step dev workflow handles this:

1. `make dev1` — uninstalls the app; go to **System Settings → Privacy & Security → Accessibility** and click **−** to remove `spacemap`
2. `make dev2` — reinstalls and relaunches; grant the permission prompt that appears

`make permissions` prints this reminder.

### The permission flow

On launch, spacemap calls `AXIsProcessTrustedWithOptions(prompt: true)` if not trusted, which opens System Settings to the Accessibility page. After you toggle it on, the app polls every second and registers the hotkey automatically — no restart needed.

### Project structure

```
spacemap/
├── Package.swift
├── Sources/spacemap/
│   ├── App.swift                 # NSApplicationMain entry point
│   ├── HUDWindowController.swift # NSPanel lifecycle + signal-driven refresh
│   ├── GridView.swift            # SwiftUI 8×2 grid layout
│   ├── CellView.swift            # Single desktop cell with window rects
│   ├── YabaiClient.swift         # yabai JSON queries
│   ├── ConfigReader.swift        # ~/.config/spacemap/config parser
│   ├── Models.swift              # YabaiSpace, YabaiWindow, GridConfig
│   ├── HotkeyMonitor.swift       # CGEventTap for Ctrl+Space
│   ├── SocketListener.swift      # Unix socket listener for yabai signals
│   └── Info.plist
└── Makefile
```
