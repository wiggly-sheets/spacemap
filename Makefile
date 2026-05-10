APP_NAME = spacemap
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
APP_CONTENTS = $(APP_BUNDLE)/Contents
INSTALL_PATH = /Applications/$(APP_BUNDLE)

.PHONY: build app install run dev uninstall clean config permissions

build:
	swift build -c release

app: build
	mkdir -p $(APP_CONTENTS)/MacOS
	mkdir -p $(APP_CONTENTS)/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_CONTENTS)/MacOS/
	cp Sources/spacemap/Info.plist $(APP_CONTENTS)/

install: app
	mkdir -p $(INSTALL_PATH)/Contents/MacOS
	mkdir -p $(INSTALL_PATH)/Contents/Resources
	cp $(APP_CONTENTS)/MacOS/$(APP_NAME) $(INSTALL_PATH)/Contents/MacOS/
	cp $(APP_CONTENTS)/Info.plist $(INSTALL_PATH)/Contents/
	codesign --force --deep --sign - $(INSTALL_PATH)
	@echo "Installed to $(INSTALL_PATH)"

run: install
	@# Always launch via 'open', never run the binary directly
	open $(INSTALL_PATH)

dev: install
	@# After rebuilding, macOS revokes Accessibility permission because the binary hash changes.
	@# This target kills the app, reinstalls, and relaunches so you just need to re-grant in System Settings.
	-killall $(APP_NAME) 2>/dev/null
	@sleep 0.5
	open $(INSTALL_PATH)
	@echo ""
	@echo "IMPORTANT: macOS revoked Accessibility permission because the binary changed."
	@echo "Go to System Settings → Privacy & Security → Accessibility"
	@echo "Remove spacemap (− button), then re-add it by granting the prompt that appears."

permissions:
	@echo "If Ctrl+Space stopped working after a reinstall:"
	@echo "  1. killall spacemap"
	@echo "  2. System Settings → Privacy & Security → Accessibility"
	@echo "  3. Click − to remove spacemap"
	@echo "  4. make run   (will prompt for permission again)"
	@echo ""
	@echo "NEVER run the binary directly — always use 'make run' or 'open $(INSTALL_PATH)'"
	@echo "Running the binary directly causes AXIsProcessTrusted() to return false."

uninstall:
	-killall $(APP_NAME) 2>/dev/null
	rm -rf $(INSTALL_PATH)
	@echo "Removed $(INSTALL_PATH)"

clean:
	rm -rf .build $(APP_BUNDLE)

config:
	mkdir -p ~/.config/spacemap
	@if [ ! -f ~/.config/spacemap/config ]; then \
		echo "GRID_COLS=8" > ~/.config/spacemap/config; \
		echo "GRID_ROWS=2" >> ~/.config/spacemap/config; \
		echo "Created ~/.config/spacemap/config with defaults (8x2)"; \
	else \
		echo "Config already exists at ~/.config/spacemap/config"; \
		cat ~/.config/spacemap/config; \
	fi
