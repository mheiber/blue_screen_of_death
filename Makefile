.PHONY: build test lint clean run bundle icon install

APP_NAME = Blue Screen of Death
BUNDLE_NAME = BlueScreenOfDeath
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(BUNDLE_NAME).app
EXECUTABLE = $(BUILD_DIR)/debug/$(BUNDLE_NAME)
ICNS_FILE = Sources/BlueScreenOfDeath/Resources/AppIcon.icns

# Generate app icon (.icns)
icon: $(ICNS_FILE)

$(ICNS_FILE): scripts/generate_icon.py
	@echo "Generating app icon..."
	@python3 scripts/generate_icon.py

# Build the executable
build:
	swift build --disable-sandbox

# Build release
release:
	swift build -c release --disable-sandbox

# Create macOS app bundle from build output
bundle: build icon
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp $(EXECUTABLE) "$(APP_BUNDLE)/Contents/MacOS/$(BUNDLE_NAME)"
	@cp Sources/BlueScreenOfDeath/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	@cp $(ICNS_FILE) "$(APP_BUNDLE)/Contents/Resources/AppIcon.icns"
	@echo "App bundle created at $(APP_BUNDLE)"

# Run the app (as a bundle so LSUIElement works)
run: bundle
	@-pkill -x BlueScreenOfDeath 2>/dev/null; sleep 0.5
	@open "$(APP_BUNDLE)"

# Run the executable directly (for quick testing, dock icon may appear)
run-debug: build
	@$(EXECUTABLE)

# Run tests
test:
	swift test --disable-sandbox

# Lint with swiftlint (if installed)
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "swiftlint not installed. Install with: brew install swiftlint"; \
	fi

# Install to /Applications (requires human interaction for copy and open)
install: bundle
	@-killall $(BUNDLE_NAME) 2>/dev/null; sleep 0.5
	@echo "Copying $(APP_BUNDLE) to /Applications..."
	cp -R "$(APP_BUNDLE)" "/Applications/$(BUNDLE_NAME).app"
	@echo "Opening from /Applications..."
	open "/Applications/$(BUNDLE_NAME).app"

# Clean build artifacts
clean:
	swift package clean
	rm -rf $(BUILD_DIR)
