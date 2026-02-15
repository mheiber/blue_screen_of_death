.PHONY: build test lint clean run bundle

APP_NAME = Blue Screen of Death
BUNDLE_NAME = BlueScreenOfDeath
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(BUNDLE_NAME).app
EXECUTABLE = $(BUILD_DIR)/debug/$(BUNDLE_NAME)

# Build the executable
build:
	swift build --disable-sandbox

# Build release
release:
	swift build -c release --disable-sandbox

# Create macOS app bundle from build output
bundle: build
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp $(EXECUTABLE) "$(APP_BUNDLE)/Contents/MacOS/$(BUNDLE_NAME)"
	@cp Sources/BlueScreenOfDeath/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	@echo "App bundle created at $(APP_BUNDLE)"

# Run the app (as a bundle so LSUIElement works)
run: bundle
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

# Clean build artifacts
clean:
	swift package clean
	rm -rf $(BUILD_DIR)
