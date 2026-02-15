import AppKit

/// Manages a full-screen blue screen overlay window that displays
/// one of four visual styles based on user preferences.
/// Any key press or mouse click dismisses the overlay.
final class BlueScreenOverlay {

    private var window: NSWindow?
    private var eventMonitor: Any?

    // MARK: - Show / Dismiss

    /// Show the blue screen overlay on the main screen.
    func show() {
        guard window == nil else { return }
        guard let screen = NSScreen.main else { return }

        // Re-randomize language each time a BSOD is triggered in random mode
        if LocalizationManager.shared.currentLanguage == "random" {
            LocalizationManager.shared.loadRandomLanguage()
        }

        let frame = screen.frame
        let style = Preferences.shared.resolveStyle()
        let bgColor = BlueScreenStyleBuilder.backgroundColor(for: style)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = true
        window.backgroundColor = bgColor
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        // Accessibility: describe the overlay for screen readers
        window.setAccessibilityRole(.popover)
        window.setAccessibilityLabel(L("a11y.overlay.label"))
        window.setAccessibilityHelp(L("a11y.overlay.hint"))

        window.contentView = BlueScreenStyleBuilder.buildView(for: style, frame: frame)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window

        // Monitor BOTH key presses AND mouse clicks
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.dismiss()
            return nil
        }

        // VoiceOver announcement: tell screen reader users the purpose
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let announcement = L("a11y.overlay.hint")
            NSAccessibility.post(
                element: NSApp as Any,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement,
                    .priority: NSAccessibilityPriorityLevel.high.rawValue,
                ]
            )
        }
    }

    /// Dismiss the overlay.
    func dismiss() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
    }
}
