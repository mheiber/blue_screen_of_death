import AppKit

/// Manages a full-screen blue screen overlay window that displays
/// one of four visual styles based on user preferences.
/// Any key press or mouse click dismisses the overlay.
final class BlueScreenOverlay {

    private var window: NSWindow?
    private var eventMonitor: Any?

    // MARK: - Colors

    private static let modernBlue = NSColor(red: 0, green: 0.47, blue: 0.84, alpha: 1)   // #0078D7
    private static let classicBlue = NSColor(red: 0, green: 0, blue: 0.667, alpha: 1)     // #0000AA

    // MARK: - Show / Dismiss

    /// Show the blue screen overlay on the main screen.
    func show() {
        guard window == nil else { return }
        guard let screen = NSScreen.main else { return }

        let frame = screen.frame
        let style = Preferences.shared.resolveStyle()
        let bgColor = (style == .modern) ? Self.modernBlue : Self.classicBlue

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

        let contentView: NSView
        switch style {
        case .modern:
            contentView = buildModernView(frame: frame)
        case .classic:
            contentView = buildClassicView(frame: frame)
        case .classicDump:
            contentView = buildClassicDumpView(frame: frame)
        case .mojibake:
            contentView = buildMojibakeView(frame: frame)
        }

        window.contentView = contentView

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

    // MARK: - Modern Style

    private func buildModernView(frame: NSRect) -> NSView {
        let data = CrashDumpGenerator.generateModernData()

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = Self.modernBlue.cgColor

        let leftMargin = frame.width * 0.15
        let maxTextWidth = frame.width * 0.6
        var yOffset = frame.height * 0.75 // Start ~25% from top (coordinate system is bottom-up)

        // ":(" emoticon
        let sadFace = NSTextField(labelWithString: ":(")
        sadFace.font = NSFont.systemFont(ofSize: 150, weight: .light)
        sadFace.textColor = .white
        sadFace.backgroundColor = .clear
        sadFace.isBezeled = false
        sadFace.isEditable = false
        sadFace.sizeToFit()
        sadFace.frame.origin = NSPoint(x: leftMargin, y: yOffset - sadFace.frame.height)
        container.addSubview(sadFace)

        yOffset -= sadFace.frame.height + 40

        // Body text
        let bodyText = """
            Your device ran into a problem and needs to restart. \
            We're just collecting some error info, and then we'll restart for you.
            """
        let bodyLabel = NSTextField(wrappingLabelWithString: bodyText)
        bodyLabel.font = NSFont.systemFont(ofSize: 18, weight: .light)
        bodyLabel.textColor = .white
        bodyLabel.backgroundColor = .clear
        bodyLabel.isBezeled = false
        bodyLabel.isEditable = false
        bodyLabel.preferredMaxLayoutWidth = maxTextWidth
        bodyLabel.frame = NSRect(x: leftMargin, y: 0, width: maxTextWidth, height: 0)
        bodyLabel.sizeToFit()
        bodyLabel.frame.origin = NSPoint(x: leftMargin, y: yOffset - bodyLabel.frame.height)
        container.addSubview(bodyLabel)

        yOffset -= bodyLabel.frame.height + 30

        // Percentage complete
        let pctLabel = NSTextField(labelWithString: "\(data.percentage)% complete")
        pctLabel.font = NSFont.systemFont(ofSize: 18, weight: .light)
        pctLabel.textColor = .white
        pctLabel.backgroundColor = .clear
        pctLabel.isBezeled = false
        pctLabel.isEditable = false
        pctLabel.sizeToFit()
        pctLabel.frame.origin = NSPoint(x: leftMargin, y: yOffset - pctLabel.frame.height)
        container.addSubview(pctLabel)

        yOffset -= pctLabel.frame.height + 60

        // QR code + info section
        let qrURL = generateFunnyURL()
        let qrSize: CGFloat = 120

        if let qrImage = generateQRCode(from: qrURL) {
            let qrView = NSImageView(frame: NSRect(
                x: leftMargin,
                y: yOffset - qrSize,
                width: qrSize,
                height: qrSize
            ))
            qrView.image = qrImage
            qrView.imageScaling = .scaleProportionallyUpOrDown
            container.addSubview(qrView)

            // Text right of QR code
            let textX = leftMargin + qrSize + 16
            let infoWidth = maxTextWidth - qrSize - 16

            let line1 = NSTextField(wrappingLabelWithString:
                "For more information about this issue and possible fixes, visit our site")
            configureSmallInfoLabel(line1, x: textX, width: infoWidth)
            line1.frame.origin.y = yOffset - line1.frame.height
            container.addSubview(line1)

            let line2 = NSTextField(wrappingLabelWithString:
                "If you call a support person, give them this info:")
            configureSmallInfoLabel(line2, x: textX, width: infoWidth)
            line2.frame.origin.y = line1.frame.origin.y - line1.frame.height - 16
            container.addSubview(line2)

            let line3 = NSTextField(labelWithString: "Stop code: \(data.stopCode)")
            configureSmallInfoLabel(line3, x: textX, width: infoWidth)
            line3.frame.origin.y = line2.frame.origin.y - line2.frame.height - 4
            container.addSubview(line3)
        }

        return container
    }

    private func configureSmallInfoLabel(_ label: NSTextField, x: CGFloat, width: CGFloat) {
        label.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        label.textColor = .white
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.preferredMaxLayoutWidth = width
        label.frame = NSRect(x: x, y: 0, width: width, height: 0)
        label.sizeToFit()
    }

    // MARK: - Classic Style

    private func buildClassicView(frame: NSRect) -> NSView {
        let crashText = CrashDumpGenerator.generate(style: .classic)

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = Self.classicBlue.cgColor

        let padding: CGFloat = 40
        let textFrame = container.bounds.insetBy(dx: padding, dy: padding)
        let textView = makeTextView(frame: textFrame, text: crashText, fontSize: 14, lineSpacing: 4)
        textView.textColor = .white

        container.addSubview(textView)
        return container
    }

    // MARK: - Classic Dump Style

    private func buildClassicDumpView(frame: NSRect) -> NSView {
        let crashText = CrashDumpGenerator.generate(style: .classicDump)

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = Self.classicBlue.cgColor

        let padding: CGFloat = 20
        let textFrame = container.bounds.insetBy(dx: padding, dy: padding)
        let lightGray = NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1) // #C0C0C0
        let textView = makeTextView(
            frame: textFrame, text: crashText, fontSize: 10.5, lineSpacing: 2, color: lightGray
        )

        container.addSubview(textView)
        return container
    }

    // MARK: - Mojibake Style

    private func buildMojibakeView(frame: NSRect) -> NSView {
        let crashText = CrashDumpGenerator.generate(style: .mojibake)

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = Self.classicBlue.cgColor

        let padding: CGFloat = 10
        let textFrame = container.bounds.insetBy(dx: padding, dy: padding)
        let textView = makeTextView(frame: textFrame, text: crashText, fontSize: 13, lineSpacing: 2)
        textView.textColor = .white

        container.addSubview(textView)
        return container
    }

    // MARK: - Shared Helpers

    private func makeTextView(
        frame: NSRect,
        text: String,
        fontSize: CGFloat,
        lineSpacing: CGFloat,
        color: NSColor = .white
    ) -> NSTextView {
        let textView = NSTextView(frame: frame)
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.autoresizingMask = [.width, .height]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
        textView.textStorage?.setAttributedString(
            NSAttributedString(string: text, attributes: attributes)
        )

        return textView
    }

    // MARK: - QR Code Generation

    private func generateQRCode(from string: String) -> NSImage? {
        guard let data = string.data(using: .ascii) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }
        // Scale up — QR codes from CIFilter are tiny
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    private func generateFunnyURL() -> String {
        let components = [
            "youarenotyourinbox", "youarefree", "breathedeep",
            "lookaway20ft", "drinkwater", "stretchnow",
            "eyesonhorizon", "standupandmove", "remembertoblink",
            "unfocusyoureyes", "feelthechairthatholdsyou",
            "youarenotyourtodolist", "theworkwillbehere",
            "thismomentisforyou", "wigglefingers", "rollshoulders",
            "takeadeepbreath", "lookatthesky", "youarehere",
            "begentle", "resetyourgaze", "nothingtoprove",
        ]
        let count = Int.random(in: 2...3)
        let selected = components.shuffled().prefix(count)
        return "https://insights.vom/" + selected.joined(separator: "/")
    }
}
