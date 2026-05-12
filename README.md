# spacemap

A native macOS work`spacemap` that shows your yabai workspace grid on demand. Press `Ctrl+Space` to toggle a floating overlay showing all your desktops as a 2D grid with window positions highlighted inside each cell.

> Inspired by [WindowMaker](https://www.windowmaker.org/) 

With [yabai](https://github.com/koekeishiya/yabai) and [skhd](https://github.com/asmvik/skhd) you can set up your desktop switching behavior to be on a grid in the macOS. 
You just don't have any visual reference that your workspaces are layed out that way. It takes alot of mental gymnastics to keep everything streight in your head.
Spacemap can help you find where you left your things.

Before you run off because I said yabai:
> You do not have to disable SIP System Integrity Protection to get this setup.

## Visualization of spacemap on a workspace
Here I have 4 windows open and `spacemap` is opened via: `ctrl spacebar` key sequence.
It is in the middle of the screen. You can see that we are on desktop 6 and there are 4 apps open.
<details><summary>Desktop Screenshot</summary>

<img width="1793" height="943" alt="Screenshot 2026-05-11 at 1 50 18 PM" src="https://github.com/user-attachments/assets/b9f2dafc-d309-4c80-98be-8d0e1f19cc17" />

</details>

## Configuration Examples
| spacemap screenshot | spacemap config | skhd config |
|---------------------|-----------------|-------------|
| <img width="711" height="136" alt="Screenshot 2026-05-11 at 1 20 00 PM" src="https://github.com/user-attachments/assets/bd9958db-07ee-466b-934c-e12d28ebd0a3" /> | <img width="195" height="75" alt="Screenshot 2026-05-11 at 1 42 02 PM" src="https://github.com/user-attachments/assets/4d493154-e1b2-4772-a408-639da7e3abe1" /> | [skhdrc](docs/skhd-configurations/skhdrc-8-by-2) |
| <img width="713" height="137" alt="Screenshot 2026-05-11 at 1 19 31 PM" src="https://github.com/user-attachments/assets/d298e386-6bc2-4ac3-8ba0-7184e2f072a5" /> | <img width="204" height="76" alt="Screenshot 2026-05-11 at 1 41 03 PM" src="https://github.com/user-attachments/assets/1a911ef2-5cb7-4746-87d1-92dddb9ec8b4" /> | [skhdrc](docs/skhd-configurations/skhdrc-8-by-2) |
| <img width="714" height="139" alt="Screenshot 2026-05-11 at 1 40 41 PM" src="https://github.com/user-attachments/assets/a4595e8b-2494-4d3b-b8cc-fcc41a4daf61" /> | <img width="199" height="76" alt="Screenshot 2026-05-11 at 1 42 45 PM" src="https://github.com/user-attachments/assets/522bc241-8d8a-4221-aad1-cc6e2e20a500" /> | [skhdrc](docs/skhd-configurations/skhdrc-8-by-2) |
| <img width="364" height="247" alt="Screenshot 2026-05-11 at 1 18 47 PM" src="https://github.com/user-attachments/assets/2eddfbc2-74a9-41dd-9d9a-cdba4f537232" /> | <img width="204" height="77" alt="Screenshot 2026-05-11 at 1 44 32 PM" src="https://github.com/user-attachments/assets/883414bb-b983-47e4-99bf-f46dd5484005" /> | [skhdrc](docs/skhd-configurations/skhdrc-4-by-4) |


Window positions are drawn as colored rectangles inside each cell (one color per app, derived from app name). The active cell updates instantly as you switch desktops, driven by yabai's `space_changed` signal.

## Usage

| Action | Result |
|--------|--------|
| `Ctrl+Space` | Toggle HUD open/closed |
| Switch desktops with skhd keymaps while HUD is open | Active cell updates live |
| Click on a workspace | switches to workspace and closes spacemap |

## Run Requirements

- macOS 13+
- [yabai](https://github.com/koekeishiya/yabai) installed at `/opt/homebrew/bin/yabai` and running
- [skhd](https://github.com/asmvik/skhd) installed at `/opt/homebrew/bin/skhd` and running
- Accessibility permission (prompted on first launch). This is not the same as disabling SIP protection, which is not required.



On first launch of spacemap macOS will prompt for Accessibility permission. Grant it — spacemap needs it to monitor the global Ctrl+Space hotkey.
<details><summary>Accessibility Permissions Screenshot</summary>
<img width="722" height="844" alt="Screenshot 2026-05-10 at 10 58 32 AM" src="https://github.com/user-attachments/assets/b6d90393-2100-44bc-ac6f-00fe1de66a98" />
</details>


## Configuration Details

Config is read from `~/.config/spacemap/config` on every HUD open (no restart needed after editing):

```bash
GRID_COLS=8
GRID_ROWS=2
```

### Cell styles

`CELL_STYLE` controls how windows are drawn inside each cell:

| Value | Description |
|-------|-------------|
| `rects` | Colored rectangles scaled from real window geometry (default) |
| `icons` | App icons at each visible window's scaled position; all apps on the workspace shown as a small icon strip at the bottom |
| `hybrid` | Colored rectangles (like `rects`) plus a small icon strip at the bottom showing all apps on the workspace |

```bash
CELL_STYLE=rects   # default
CELL_STYLE=icons
CELL_STYLE=hybrid
```

## Install ( in 3 steps )
1. Install Pre-Requesits 
2. Install spacemap
3. Cofigure skhd 
4. Configure spacemap
`ctrl space`

**Step 1: Install Pre-Requesits**
```
brew install asmvik/formulae/yabai
brew install asmvik/formulae/skhd
```

**Step 2: Install spacemap**
```
brew tap jsheffie/tap
brew install --cask jsheffie/tap/spacemap
```

**Step 3: Configure skhd**

Copy the 8×2 grid keymap into your skhd config:
```bash
curl -fsSL https://raw.githubusercontent.com/jsheffie/spacemap/main/docs/skhd-configurations/skhdrc-8-by-2 \
  > ~/.config/skhd/skhdrc
```

Then restart skhd:
```bash
skhd --restart-service
```

**Step 4: Configure spacemap**

```bash
mkdir -p ~/.config/spacemap
cat > ~/.config/spacemap/config << 'EOF'
GRID_COLS=8
GRID_ROWS=2
CELL_STYLE=hybrid
EOF
```

Press `Ctrl+Space` to open spacemap.


## Build Requirements
- Xcode Command Line Tools (`xcode-select --install`)


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

macOS grants Accessibility permission to the `.app` bundle as a whole, not the raw binary. Running the binary directly bypasses the bundle context and the permission check fails silently.

### Accessibility permission is revoked on every reinstall

Every time you rebuild and reinstall, macOS revokes the Accessibility permission because the binary hash changes. The two-step dev workflow handles this:

1. `make dev1` — uninstalls the app; go to **System Settings → Privacy & Security → Accessibility** and click **−** to remove `spacemap`
2. `make dev2` — reinstalls and relaunches; grant the permission prompt that appears

`make permissions` prints this reminder.

### The permission flow

On launch, spacemap calls `AXIsProcessTrustedWithOptions(prompt: true)` if not trusted, which opens System Settings to the Accessibility page. After you toggle it on, the app polls every second and registers the hotkey automatically — no restart needed.

