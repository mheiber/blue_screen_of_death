import AppKit

/// Pure view factory that builds blue screen style views for any frame size.
/// Used by both BlueScreenOverlay (full-screen) and StylePreviewController (preview).
struct BlueScreenStyleBuilder {

    // MARK: - Colors

    static let modernBlue = NSColor(red: 0, green: 0.47, blue: 0.84, alpha: 1)   // #0078D7
    static let classicBlue = NSColor(red: 0, green: 0, blue: 0.667, alpha: 1)     // #0000AA

    /// Returns the background color for a given style.
    static func backgroundColor(for style: ScreenStyle) -> NSColor {
        switch style {
        case .modern:
            return modernBlue
        case .cyberwin2070:
            return CyberWin2070StyleBuilder.darkBg
        default:
            return classicBlue
        }
    }

    /// Build the view for a given style at the given frame.
    static func buildView(for style: ScreenStyle, frame: NSRect) -> NSView {
        switch style {
        case .modern:
            return buildModernView(frame: frame)
        case .classic:
            return buildClassicView(frame: frame)
        case .classicDump:
            return buildClassicDumpView(frame: frame)
        case .mojibake:
            return buildMojibakeView(frame: frame)
        case .cyberwin2070:
            return CyberWin2070StyleBuilder.buildView(frame: frame)
        }
    }

    // MARK: - Modern Style

    private static func buildModernView(frame: NSRect) -> NSView {
        let data = CrashDumpGenerator.generateModernData()

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = modernBlue.cgColor

        let leftMargin = frame.width * 0.15
        let maxTextWidth = frame.width * 0.6
        var yOffset = frame.height * 0.75

        // ":(" emoticon
        let sadFaceSize = min(150, frame.height * 0.2)
        let sadFace = NSTextField(labelWithString: ":(")
        sadFace.font = NSFont.systemFont(ofSize: sadFaceSize, weight: .light)
        sadFace.textColor = .white
        sadFace.backgroundColor = .clear
        sadFace.isBezeled = false
        sadFace.isEditable = false
        sadFace.sizeToFit()
        sadFace.frame.origin = NSPoint(x: leftMargin, y: yOffset - sadFace.frame.height)
        container.addSubview(sadFace)

        yOffset -= sadFace.frame.height + 40

        // Body text
        let bodyText = L("bsod.modern.body")
        let bodyFontSize = min(18.0, frame.height * 0.025)
        let bodyLabel = NSTextField(wrappingLabelWithString: bodyText)
        bodyLabel.font = NSFont.systemFont(ofSize: bodyFontSize, weight: .light)
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
        let pctLabel = NSTextField(labelWithString: L("bsod.modern.percentComplete", data.percentage))
        pctLabel.font = NSFont.systemFont(ofSize: bodyFontSize, weight: .light)
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
        let qrSize = min(120.0, frame.height * 0.15)

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

            let textX = leftMargin + qrSize + 16
            let infoWidth = maxTextWidth - qrSize - 16

            let line1 = NSTextField(wrappingLabelWithString:
                L("bsod.modern.moreInfo"))
            configureSmallInfoLabel(line1, x: textX, width: infoWidth)
            line1.frame.origin.y = yOffset - line1.frame.height
            container.addSubview(line1)

            let line2 = NSTextField(wrappingLabelWithString:
                L("bsod.modern.supportInfo"))
            configureSmallInfoLabel(line2, x: textX, width: infoWidth)
            line2.frame.origin.y = line1.frame.origin.y - line1.frame.height - 16
            container.addSubview(line2)

            let line3 = NSTextField(labelWithString: L("bsod.modern.stopCode", data.stopCode))
            configureSmallInfoLabel(line3, x: textX, width: infoWidth)
            line3.frame.origin.y = line2.frame.origin.y - line2.frame.height - 4
            container.addSubview(line3)
        }

        return container
    }

    private static func configureSmallInfoLabel(_ label: NSTextField, x: CGFloat, width: CGFloat) {
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

    private static func buildClassicView(frame: NSRect) -> NSView {
        let crashText = CrashDumpGenerator.generate(style: .classic)

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = classicBlue.cgColor

        let padding: CGFloat = 40
        let textFrame = container.bounds.insetBy(dx: padding, dy: padding)
        let textView = makeTextView(frame: textFrame, text: crashText, fontSize: 14, lineSpacing: 4)
        textView.textColor = .white

        container.addSubview(textView)
        return container
    }

    // MARK: - Classic Dump Style

    private static func buildClassicDumpView(frame: NSRect) -> NSView {
        let crashText = CrashDumpGenerator.generate(style: .classicDump)

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = classicBlue.cgColor

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

    private static func buildMojibakeView(frame: NSRect) -> NSView {
        let crashText = CrashDumpGenerator.generate(style: .mojibake)

        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = classicBlue.cgColor

        let padding: CGFloat = 10
        let textFrame = container.bounds.insetBy(dx: padding, dy: padding)
        let textView = makeTextView(frame: textFrame, text: crashText, fontSize: 13, lineSpacing: 2)
        textView.textColor = .white

        container.addSubview(textView)
        return container
    }

    // MARK: - Shared Helpers

    private static func makeTextView(
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

    static func generateQRCode(from string: String) -> NSImage? {
        guard let data = string.data(using: .ascii) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    static func generateFunnyURL() -> String {
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
