# Contributing to spacemap

## Welcome!

We're excited to have you contribute to spacemap. This is a native macOS utility that visualizes yabai workspaces in a floating 2D grid overlay.

## Development Workflow

### Prerequisites
- macOS 13+ (Ventura or later)
- Xcode Command Line Tools: `xcode-select --install`
- yabai installed at `/opt/homebrew/bin/yabai`: `brew install asmvik/formulae/yabai`
- skhd installed at `/opt/homebrew/bin/skhd`: `brew install asmvik/formulae/skhd`

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jsheffie/spacemap.git
   cd spacemap
   ```

2. **Build the app:**
   ```bash
   make app
   ```

3. **Install and launch:**
   ```bash
   make dev1  # Uninstall if already installed
   # Remove spacemap from System Settings → Privacy & Security → Accessibility
   make dev2  # Rebuild, reinstall, and launch
   ```

4. **Grant Accessibility permission** when prompted.

### Building & Running

| Command | Description |
|---------|-------------|
| `make build` | Build release binary |
| `make app` | Build and assemble `.app` bundle |
| `make run` | Build, install to `/Applications`, and launch |
| `make dev1` | Uninstall from `/Applications` |
| `make dev2` | Rebuild, reinstall, and launch |
| `make clean` | Remove build artifacts |
| `make config` | Create default config file |

## Code Style

- **Swift 5.9+** with Swift Package Manager
- **No external dependencies** - pure AppKit + SwiftUI
- **Follow existing code style** - consistency is key
- **No forced unwraps** - use `guard`/`if let` safely
- **Minimal comments** - write self-documenting code

## Contribution Guidelines

### Bug Fixes
1. **Reproduce the issue** - document steps to trigger it
2. **Fix the root cause** - don't bandage symptoms
3. **Test thoroughly** - verify fix works in all scenarios
4. **Update docs** - add notes to `TASKS.md` if needed

### New Features
1. **Check TASKS.md** - see if it's already planned
2. **Open an issue first** - describe the feature and get feedback
3. **Start small** - minimal viable implementation
4. **Test with yabai** - verify actual workspace interactions

### Code Changes
- **Edit existing files only** - no new files unless absolutely necessary
- **Small diffs** - 1-2 file edits preferred
- **No refactors** - don't rewrite entire modules
- **No comments** - keep it lean, add only if absolutely required

### Pull Requests
- **Title format:** `verb: what changed` (e.g., `Fix: handle yabai not running`)
- **Description:** brief explanation of changes and testing steps
- **Screenshots:** if UI changes, include before/after images

## Important Constraints

1. **yabai path:** Hardcoded to `/opt/homebrew/bin/yabai` - no auto-discovery
2. **Accessibility:** Required for hotkeys, handled on launch
3. **Permissions:** Rebuilds revoke permissions - use `make dev1`/`dev2` workflow
4. **Config:** Reloaded on every HUD open (except `HOTKEY` which needs restart)

## Testing

### Manual Testing Checklist
- [ ] Launch app with yabai running → HUD opens on hotkey
- [ ] Switch spaces while HUD visible → active cell updates
- [ ] Click cell → switch space and close HUD
- [ ] Drag window over cell → window moves to target space
- [ ] Config change → HUD reflects new settings on next open
- [ ] Kill yabai → app shows error dialog and exits
- [ ] Deny Accessibility → app prompts for permission
- [ ] Auto-hide → HUD closes after timeout

### Common Test Scenarios
1. **Config parsing:** Add inline comments (`# comment`) and verify parsing
2. **Scale testing:** Set `UI_SCALE=0.5` → verify 5× size
3. **Theme testing:** Set `THEME=tokyonight` → verify colors
4. **Signal testing:** `yabai --signal --emit spacemap_show` → HUD shows

## Known Limitations

- **Homebrew only:** No other package managers supported
- **Apple Silicon only:** No Intel Mac support (hardcoded `/opt/homebrew`)
- **No tests:** Unit tests not implemented yet
- **Icon flicker:** Re-fetching icons causes visual artifacts

## Getting Help

- Check `DEVELOPER.md` for technical deep-dive
- Check `TASKS.md` for roadmap and known issues
- Check `README.md` for user-facing documentation

## Code of Conduct

- Be respectful and patient
- Focus on the code, not the person
- Accept constructive criticism gracefully
- Help others learn and grow

Thank you for contributing to spacemap!