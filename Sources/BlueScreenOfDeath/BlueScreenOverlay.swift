import AppKit

/// Manages a full-screen blue screen overlay window that displays
/// a randomized crash dump with mindfulness messages.
/// Any key press dismisses the overlay.
final class BlueScreenOverlay {

    private var window: NSWindow?
    private var eventMonitor: Any?

    /// Show the blue screen overlay on the main screen.
    func show() {
        guard window == nil else { return }

        guard let screen = NSScreen.main else { return }
        let frame = screen.frame

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = true
        window.backgroundColor = NSColor(red: 0, green: 0, blue: 0.667, alpha: 1) // #0000AA
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        // Build the crash dump text view
        let contentView = NSView(frame: frame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0.667, alpha: 1).cgColor

        let style = Preferences.shared.resolveStyle()
        let crashText = CrashDumpGenerator.generate(style: style)

        let textView = NSTextView(frame: contentView.bounds.insetBy(dx: 60, dy: 60))
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textColor = .white
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.string = crashText
        textView.alignment = .left
        textView.autoresizingMask = [.width, .height]

        // Set paragraph style for line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
        ]
        textView.textStorage?.setAttributedString(
            NSAttributedString(string: crashText, attributes: attributes)
        )

        contentView.addSubview(textView)
        window.contentView = contentView

        // Show instantly, no animation
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window

        // Monitor for any key press to dismiss
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.dismiss()
            return nil // consume the event
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
