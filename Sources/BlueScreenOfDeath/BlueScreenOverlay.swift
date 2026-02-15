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
