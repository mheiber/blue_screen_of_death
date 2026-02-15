import AppKit

/// Manages hover-preview windows for the style submenu.
/// Shows a dimmed background with a centered preview of the selected style.
final class StylePreviewController {

    private var dimmingWindows: [NSWindow] = []
    private var previewWindow: NSWindow?
    private var currentStyle: ScreenStyle?
    private var isShowingRandom = false
    private var cycleTimer: Timer?

    /// Show a preview for the given style, or nil for Random (cycles through all styles).
    func showPreview(for style: ScreenStyle?) {
        if let style = style {
            if style == currentStyle && !isShowingRandom { return }
        } else {
            if isShowingRandom && previewWindow != nil { return }
        }

        hidePreview()

        guard let mainScreen = NSScreen.main else { return }

        // Dimming windows — one per screen
        for screen in NSScreen.screens {
            let dimWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            dimWindow.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue - 2)
            dimWindow.isOpaque = false
            dimWindow.backgroundColor = NSColor.black.withAlphaComponent(0.5)
            dimWindow.ignoresMouseEvents = true
            dimWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            dimWindow.isReleasedWhenClosed = false
            dimWindow.orderFront(nil)
            dimmingWindows.append(dimWindow)
        }

        // Preview window — 60% of main screen, centered
        let previewWidth = mainScreen.frame.width * 0.6
        let previewHeight = mainScreen.frame.height * 0.6
        let previewX = mainScreen.frame.origin.x + (mainScreen.frame.width - previewWidth) / 2
        let previewY = mainScreen.frame.origin.y + (mainScreen.frame.height - previewHeight) / 2
        let previewFrame = NSRect(x: previewX, y: previewY, width: previewWidth, height: previewHeight)

        if let style = style {
            currentStyle = style
            isShowingRandom = false
            showSingleStylePreview(style: style, frame: previewFrame)
        } else {
            currentStyle = nil
            isShowingRandom = true
            showRandomPreview(frame: previewFrame)
        }
    }

    /// Hide the preview and clean up all windows.
    func hidePreview() {
        cycleTimer?.invalidate()
        cycleTimer = nil

        previewWindow?.orderOut(nil)
        previewWindow = nil

        for w in dimmingWindows {
            w.orderOut(nil)
        }
        dimmingWindows.removeAll()

        currentStyle = nil
        isShowingRandom = false
    }

    // MARK: - Private

    private func showSingleStylePreview(style: ScreenStyle, frame: NSRect) {
        let bgColor = BlueScreenStyleBuilder.backgroundColor(for: style)
        let contentFrame = NSRect(origin: .zero, size: frame.size)
        let contentView = BlueScreenStyleBuilder.buildView(for: style, frame: contentFrame)

        let window = makePreviewWindow(frame: frame, bgColor: bgColor)
        window.contentView = contentView
        window.orderFront(nil)
        previewWindow = window
    }

    private func showRandomPreview(frame: NSRect) {
        var styleIndex = Int.random(in: 0..<ScreenStyle.allCases.count)
        let firstStyle = ScreenStyle.allCases[styleIndex]
        showSingleStylePreview(style: firstStyle, frame: frame)

        cycleTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            styleIndex = (styleIndex + 1) % ScreenStyle.allCases.count
            let nextStyle = ScreenStyle.allCases[styleIndex]

            let contentFrame = NSRect(origin: .zero, size: frame.size)
            let contentView = BlueScreenStyleBuilder.buildView(for: nextStyle, frame: contentFrame)
            let bgColor = BlueScreenStyleBuilder.backgroundColor(for: nextStyle)

            self.previewWindow?.backgroundColor = bgColor
            self.previewWindow?.contentView = contentView
        }
    }

    private func makePreviewWindow(frame: NSRect, bgColor: NSColor) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue - 1)
        window.isOpaque = true
        window.backgroundColor = bgColor
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        return window
    }
}
