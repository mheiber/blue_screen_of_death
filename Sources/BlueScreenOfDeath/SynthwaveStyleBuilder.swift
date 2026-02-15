import AppKit

// MARK: - Scan Line Overlay

/// A custom NSView that draws horizontal CRT scan lines across its entire bounds.
private final class ScanLineView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let lineSpacing: CGFloat = 3
        let lineHeight: CGFloat = 1
        // Semi-transparent dark lines to simulate CRT phosphor gaps
        context.setFillColor(NSColor.black.withAlphaComponent(0.12).cgColor)

        var y: CGFloat = 0
        while y < bounds.height {
            context.fill(CGRect(x: 0, y: y, width: bounds.width, height: lineHeight))
            y += lineSpacing
        }
    }
}

// MARK: - Perspective Grid View

/// A custom NSView that draws a retrowave perspective grid converging toward a vanishing point.
/// The grid occupies the bottom portion of the view and fades toward the horizon line.
private final class PerspectiveGridView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let vanishingPoint = NSPoint(x: bounds.midX, y: bounds.height)
        let gridBottom: CGFloat = 0
        let gridTop = bounds.height
        let gridHeight = gridTop - gridBottom

        // -- Horizontal lines (perspective-foreshortened) --
        let horizontalLineCount = 20
        for i in 0...horizontalLineCount {
            // Use exponential distribution so lines bunch up near the horizon
            let t = CGFloat(i) / CGFloat(horizontalLineCount)
            let exponentialT = pow(t, 2.2) // more lines near the bottom, sparse near horizon
            let y = gridBottom + exponentialT * gridHeight

            // Fade alpha: bright at bottom, dim at top
            let alpha = max(0.05, 1.0 - pow(t, 0.8)) * 0.55

            // Width narrows as we approach the vanishing point
            let perspectiveFactor = 1.0 - (y - gridBottom) / gridHeight
            let halfWidth = (bounds.width * 0.7) * perspectiveFactor + bounds.width * 0.02

            let lineColor = NSColor(
                red: 1.0,
                green: 0.16,
                blue: 0.46,
                alpha: alpha * 0.6
            )
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(max(0.5, 1.2 * (1.0 - t)))

            let path = NSBezierPath()
            path.move(to: NSPoint(x: vanishingPoint.x - halfWidth, y: y))
            path.line(to: NSPoint(x: vanishingPoint.x + halfWidth, y: y))
            path.stroke()

            // Glow pass: same line, wider and more transparent
            let glowColor = NSColor(
                red: 1.0,
                green: 0.16,
                blue: 0.46,
                alpha: alpha * 0.15
            )
            context.setStrokeColor(glowColor.cgColor)
            context.setLineWidth(max(1.5, 4.0 * (1.0 - t)))
            let glowPath = NSBezierPath()
            glowPath.move(to: NSPoint(x: vanishingPoint.x - halfWidth, y: y))
            glowPath.line(to: NSPoint(x: vanishingPoint.x + halfWidth, y: y))
            glowPath.stroke()
        }

        // -- Vertical lines converging to vanishing point --
        let verticalLineCount = 24
        for i in 0...verticalLineCount {
            let t = CGFloat(i) / CGFloat(verticalLineCount)
            // Bottom x position spans beyond the view for dramatic perspective
            let bottomX = -bounds.width * 0.3 + t * bounds.width * 1.6

            let alpha: CGFloat = 0.35
            let lineColor = NSColor(
                red: 0.0,
                green: 1.0,
                blue: 0.96,
                alpha: alpha * 0.5
            )

            // Create gradient effect: bright at bottom, fading toward horizon
            let path = NSBezierPath()
            path.move(to: NSPoint(x: bottomX, y: gridBottom))
            path.line(to: vanishingPoint)

            context.saveGState()

            // Line color
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(0.8)
            path.stroke()

            // Glow pass
            let glowColor = NSColor(
                red: 0.0,
                green: 1.0,
                blue: 0.96,
                alpha: alpha * 0.12
            )
            context.setStrokeColor(glowColor.cgColor)
            context.setLineWidth(3.0)
            path.stroke()

            context.restoreGState()
        }

        // -- Horizon glow: a soft radial gradient at the vanishing point --
        let gradientColors = [
            NSColor(red: 0.69, green: 0.15, blue: 1.0, alpha: 0.35).cgColor,
            NSColor(red: 0.69, green: 0.15, blue: 1.0, alpha: 0.0).cgColor,
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0, 1]) {
            context.saveGState()
            context.drawRadialGradient(
                gradient,
                startCenter: vanishingPoint,
                startRadius: 0,
                endCenter: vanishingPoint,
                endRadius: bounds.width * 0.45,
                options: []
            )
            context.restoreGState()
        }
    }
}

// MARK: - Synthwave Style Builder

/// Builds the synthwave/laserwave themed BSOD view.
///
/// This produces a retro-futuristic terminal-style crash screen with neon colors,
/// CRT scan lines, a perspective grid horizon, and randomly-generated fake stack traces
/// styled like syntax-highlighted terminal output.
struct SynthwaveStyleBuilder {

    // MARK: - Color Constants

    /// Deep purple-black background
    static let darkBg = NSColor(red: 0.102, green: 0.039, blue: 0.180, alpha: 1.0) // #1a0a2e

    /// Hot pink for keywords and accents
    static let neonPink = NSColor(red: 1.0, green: 0.161, blue: 0.459, alpha: 1.0) // #FF2975

    /// Electric cyan for numbers and hex values
    static let electricCyan = NSColor(red: 0.0, green: 1.0, blue: 0.961, alpha: 1.0) // #00FFF5

    /// Neon purple for strings and paths
    static let neonPurple = NSColor(red: 0.690, green: 0.149, blue: 1.0, alpha: 1.0) // #B026FF

    /// Laser orange for operators and brackets
    static let laserOrange = NSColor(red: 1.0, green: 0.420, blue: 0.208, alpha: 1.0) // #FF6B35

    /// Electric blue for decorative accents
    static let electricBlue = NSColor(red: 0.302, green: 0.302, blue: 1.0, alpha: 1.0) // #4D4DFF

    /// Dimmer cyan for regular body text
    static let dimCyan = NSColor(red: 0.55, green: 0.82, blue: 0.85, alpha: 1.0)

    /// Slightly brighter body text
    static let softWhite = NSColor(red: 0.78, green: 0.85, blue: 0.90, alpha: 1.0)

    // MARK: - Font Cascade

    /// Returns the best available monospaced programmer font, trying
    /// JetBrains Mono first, then Fira Code, then SF Mono as a system fallback.
    static func programmerFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        // Map NSFont.Weight to a PostScript-name suffix for the lookup fonts
        let weightSuffix: String
        switch weight {
        case .bold:
            weightSuffix = "Bold"
        case .medium:
            weightSuffix = "Medium"
        case .semibold:
            weightSuffix = "SemiBold"
        case .light:
            weightSuffix = "Light"
        default:
            weightSuffix = "Regular"
        }

        // Try JetBrains Mono
        if let font = NSFont(name: "JetBrainsMono-\(weightSuffix)", size: size) {
            return font
        }
        if let font = NSFont(name: "JetBrains Mono", size: size) {
            return font
        }

        // Try Fira Code
        if let font = NSFont(name: "FiraCode-\(weightSuffix)", size: size) {
            return font
        }
        if let font = NSFont(name: "Fira Code", size: size) {
            return font
        }

        // Fallback to SF Mono (system monospaced)
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }

    // MARK: - Public Entry Point

    /// Build the synthwave-themed view for the given frame.
    /// The view is fully self-contained and works at any size (full-screen or preview).
    static func buildView(frame: NSRect) -> NSView {
        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = darkBg.cgColor

        // 1. Background gradient layer (subtle vignette)
        addBackgroundGradient(to: container)

        // 2. Perspective grid in the bottom ~28% of the screen
        let gridHeight = frame.height * 0.28
        let gridView = PerspectiveGridView(frame: NSRect(
            x: 0, y: 0, width: frame.width, height: gridHeight
        ))
        container.addSubview(gridView)

        // 3. Foreground content: prompt, body text, progress, QR code
        addForegroundContent(to: container, frame: frame)

        // 4. Scan lines on top of everything
        let scanLines = ScanLineView(frame: frame)
        container.addSubview(scanLines)

        return container
    }

    // MARK: - Background

    private static func addBackgroundGradient(to container: NSView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = container.bounds
        gradientLayer.colors = [
            NSColor(red: 0.08, green: 0.02, blue: 0.15, alpha: 1.0).cgColor,
            darkBg.cgColor,
            NSColor(red: 0.14, green: 0.04, blue: 0.22, alpha: 1.0).cgColor,
            NSColor(red: 0.08, green: 0.02, blue: 0.12, alpha: 1.0).cgColor,
        ]
        gradientLayer.locations = [0.0, 0.3, 0.65, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        container.layer?.addSublayer(gradientLayer)
    }

    // MARK: - Foreground Content

    private static func addForegroundContent(to container: NSView, frame: NSRect) {
        let leftMargin = frame.width * 0.12
        let maxTextWidth = frame.width * 0.65
        var yOffset = frame.height * 0.80

        // -- Terminal cursor prompt: >>_ --
        let promptSize = min(120, frame.height * 0.16)
        let promptLabel = NSTextField(labelWithString: ">>_")
        promptLabel.font = programmerFont(size: promptSize, weight: .bold)
        promptLabel.textColor = neonPink
        promptLabel.backgroundColor = .clear
        promptLabel.isBezeled = false
        promptLabel.isEditable = false
        promptLabel.shadow = makeGlow(color: neonPink, radius: 18)
        promptLabel.sizeToFit()
        promptLabel.frame.origin = NSPoint(x: leftMargin, y: yOffset - promptLabel.frame.height)
        container.addSubview(promptLabel)

        // Extra glow layer behind the prompt for bloom effect
        let promptGlow = NSTextField(labelWithString: ">>_")
        promptGlow.font = programmerFont(size: promptSize, weight: .bold)
        promptGlow.textColor = neonPink.withAlphaComponent(0.3)
        promptGlow.backgroundColor = .clear
        promptGlow.isBezeled = false
        promptGlow.isEditable = false
        promptGlow.shadow = makeGlow(color: neonPink, radius: 40)
        promptGlow.sizeToFit()
        promptGlow.frame.origin = promptLabel.frame.origin
        container.addSubview(promptGlow, positioned: .below, relativeTo: promptLabel)

        yOffset -= promptLabel.frame.height + frame.height * 0.03

        // -- Body: syntax-highlighted fake stack trace --
        let bodyFontSize = clampedFontSize(min: 10.0, max: 16.0, fraction: 0.018, frameHeight: frame.height)
        let traceData = generateStackTrace()
        let attributedTrace = syntaxHighlight(traceData, fontSize: bodyFontSize)

        let traceView = NSTextView(frame: NSRect(
            x: leftMargin, y: 0, width: maxTextWidth, height: frame.height * 0.4
        ))
        traceView.isEditable = false
        traceView.isSelectable = false
        traceView.drawsBackground = false
        traceView.textStorage?.setAttributedString(attributedTrace)
        traceView.sizeToFit()

        // Position from the top
        let traceHeight = min(traceView.frame.height, frame.height * 0.35)
        traceView.frame = NSRect(
            x: leftMargin,
            y: yOffset - traceHeight,
            width: maxTextWidth,
            height: traceHeight
        )
        container.addSubview(traceView)

        yOffset -= traceHeight + frame.height * 0.03

        // -- Progress bar --
        let percentage = Int.random(in: 12...94)
        let progressFontSize = clampedFontSize(min: 10.0, max: 14.0, fraction: 0.016, frameHeight: frame.height)
        let progressText = generateProgressBar(percentage: percentage)
        let progressAttr = syntaxHighlight(progressText, fontSize: progressFontSize)

        let progressView = NSTextView(frame: NSRect(
            x: leftMargin, y: 0, width: maxTextWidth, height: 30
        ))
        progressView.isEditable = false
        progressView.isSelectable = false
        progressView.drawsBackground = false
        progressView.textStorage?.setAttributedString(progressAttr)
        progressView.sizeToFit()
        progressView.frame.origin = NSPoint(x: leftMargin, y: yOffset - progressView.frame.height)
        container.addSubview(progressView)

        yOffset -= progressView.frame.height + frame.height * 0.05

        // -- QR code + info section --
        let qrURL = BlueScreenStyleBuilder.generateFunnyURL()
        let qrSize = min(100.0, frame.height * 0.12)

        if let qrImage = BlueScreenStyleBuilder.generateQRCode(from: qrURL) {
            let qrView = NSImageView(frame: NSRect(
                x: leftMargin,
                y: yOffset - qrSize,
                width: qrSize,
                height: qrSize
            ))
            qrView.image = qrImage
            qrView.imageScaling = .scaleProportionallyUpOrDown

            // Tint the QR code area with a neon border glow
            qrView.wantsLayer = true
            qrView.layer?.borderColor = electricCyan.withAlphaComponent(0.4).cgColor
            qrView.layer?.borderWidth = 1
            qrView.layer?.shadowColor = electricCyan.cgColor
            qrView.layer?.shadowRadius = 8
            qrView.layer?.shadowOpacity = 0.5
            qrView.layer?.shadowOffset = .zero

            container.addSubview(qrView)

            let textX = leftMargin + qrSize + 16
            let infoWidth = maxTextWidth - qrSize - 16
            let infoFontSize = clampedFontSize(min: 8.0, max: 11.0, fraction: 0.013, frameHeight: frame.height)

            let line1 = makeInfoLabel(
                text: "> scan for diagnostic report",
                fontSize: infoFontSize, color: dimCyan, width: infoWidth
            )
            line1.frame.origin = NSPoint(x: textX, y: yOffset - line1.frame.height)
            container.addSubview(line1)

            let line2 = makeInfoLabel(
                text: "> ref: \(randomHexShort())-\(randomHexShort())-\(randomHexShort())",
                fontSize: infoFontSize, color: electricCyan, width: infoWidth
            )
            line2.frame.origin = NSPoint(x: textX, y: line1.frame.origin.y - line2.frame.height - 4)
            line2.shadow = makeGlow(color: electricCyan, radius: 6)
            container.addSubview(line2)

            let stopCode = CrashDumpGenerator.generateModernData().stopCode
            let line3 = makeInfoLabel(
                text: "> halt_code: \(stopCode)",
                fontSize: infoFontSize, color: neonPurple, width: infoWidth
            )
            line3.frame.origin = NSPoint(x: textX, y: line2.frame.origin.y - line3.frame.height - 4)
            line3.shadow = makeGlow(color: neonPurple, radius: 5)
            container.addSubview(line3)
        }
    }

    // MARK: - Stack Trace Generation

    /// Token types for syntax highlighting
    private enum TokenType {
        case keyword     // FATAL, ERROR, SYSTEM, etc.
        case number      // hex values, addresses, signal numbers
        case string      // paths, process names in quotes
        case `operator`  // brackets, colons, arrows, operators
        case plain       // regular text
    }

    /// A token is a piece of text with a type for coloring.
    private struct Token {
        let text: String
        let type: TokenType
    }

    /// Randomly generates a plausible fake stack trace / system log.
    /// Each call produces different output.
    private static func generateStackTrace() -> [[Token]] {
        var lines: [[Token]] = []

        let processNames = [
            "wscore.daemon", "wsgl.driver", "ws_render", "ws_compositor",
            "wskerneld", "ws_display", "ws_audiod", "ws_netd",
            "ws_fsd", "ws_usbd", "ws_powerd", "ws_cryptd",
            "ws_scheduled", "ws_sessiond",
        ]

        let moduleNames = [
            "uwsp.so", "wsgl.driver", "libwscore.dylib", "wsfs.kext",
            "wsnet.framework", "wsk_security.so", "libwsrender.dylib",
            "wsinput.kext", "wscache.so", "wsvm.dylib",
        ]

        let segments = [".text", ".data", ".bss", ".rodata", ".heap", ".stack"]

        let faultTypes = [
            "memory_fault", "segmentation_fault", "bus_error",
            "stack_overflow", "heap_corruption", "null_deref",
            "double_free", "use_after_free", "buffer_overrun",
        ]

        let haltReasons = [
            "SYSTEM_HALT", "KERNEL_PANIC", "FATAL_EXCEPTION",
            "UNRECOVERABLE_ERROR", "WATCHDOG_TIMEOUT", "TRIPLE_FAULT",
        ]

        // Line 1: [FATAL] header
        let addr1 = randomHex8()
        lines.append([
            Token(text: "[", type: .operator),
            Token(text: "FATAL", type: .keyword),
            Token(text: "] ", type: .operator),
            Token(text: "kernel.panic", type: .plain),
            Token(text: " at ", type: .plain),
            Token(text: "0x\(addr1)", type: .number),
        ])

        // Line 2: SYSTEM_HALT line
        let process = processNames.randomElement()!
        let signal = Int.random(in: 1...15)
        let haltReason = haltReasons.randomElement()!
        lines.append([
            Token(text: "> ", type: .operator),
            Token(text: haltReason, type: .keyword),
            Token(text: ": process ", type: .plain),
            Token(text: "'\(process)'", type: .string),
            Token(text: " exited ", type: .plain),
            Token(text: "(", type: .operator),
            Token(text: "signal \(signal)", type: .number),
            Token(text: ")", type: .operator),
        ])

        // Line 3: memory fault
        let fault = faultTypes.randomElement()!
        let faultAddr = randomHex8()
        let seg = segments.randomElement()!
        lines.append([
            Token(text: "> ", type: .operator),
            Token(text: fault, type: .plain),
            Token(text: ": addr=", type: .operator),
            Token(text: "0x\(faultAddr)", type: .number),
            Token(text: " segment=", type: .operator),
            Token(text: seg, type: .string),
        ])

        // Lines 4-5: stack trace entries
        let traceCount = Int.random(in: 2...4)
        for _ in 0..<traceCount {
            let mod1 = moduleNames.randomElement()!
            let mod2 = moduleNames.randomElement()!
            let off1 = String(format: "0x%X", Int.random(in: 0x100...0xFFF))
            let off2 = String(format: "0x%X", Int.random(in: 0x100...0xFFF))
            lines.append([
                Token(text: "> ", type: .operator),
                Token(text: "stack_trace", type: .plain),
                Token(text: ": ", type: .operator),
                Token(text: mod1, type: .string),
                Token(text: "+", type: .operator),
                Token(text: off1, type: .number),
                Token(text: " :: ", type: .operator),
                Token(text: mod2, type: .string),
                Token(text: "+", type: .operator),
                Token(text: off2, type: .number),
            ])
        }

        // Line: register dump
        lines.append([
            Token(text: "> ", type: .operator),
            Token(text: "registers", type: .plain),
            Token(text: ": ", type: .operator),
            Token(text: "rip=", type: .operator),
            Token(text: "0x\(randomHex8())", type: .number),
            Token(text: " rsp=", type: .operator),
            Token(text: "0x\(randomHex8())", type: .number),
            Token(text: " rbp=", type: .operator),
            Token(text: "0x\(randomHex8())", type: .number),
        ])

        // Line: ERROR
        let driver = moduleNames.randomElement()!
        lines.append([
            Token(text: "[", type: .operator),
            Token(text: "ERROR", type: .keyword),
            Token(text: "] ", type: .operator),
            Token(text: "failed to unload ", type: .plain),
            Token(text: "'\(driver)'", type: .string),
            Token(text: " -- ", type: .operator),
            Token(text: "resource busy", type: .plain),
        ])

        // Blank line
        lines.append([Token(text: "", type: .plain)])

        // Core dump progress
        let pct = Int.random(in: 30...85)
        let filled = Int(Double(pct) / 100.0 * 20.0)
        let empty = 20 - filled
        let bar = String(repeating: "=", count: filled) + ">" + String(repeating: " ", count: max(0, empty - 1))
        lines.append([
            Token(text: "> ", type: .operator),
            Token(text: "dumping core", type: .plain),
            Token(text: "... ", type: .operator),
            Token(text: "[", type: .operator),
            Token(text: bar, type: .number),
            Token(text: "] ", type: .operator),
            Token(text: "\(pct)%", type: .number),
        ])

        return lines
    }

    /// Generates a progress bar line as tokens.
    private static func generateProgressBar(percentage: Int) -> [[Token]] {
        let filled = Int(Double(percentage) / 100.0 * 30.0)
        let empty = 30 - filled
        let bar = String(repeating: "#", count: filled) + String(repeating: ".", count: empty)
        return [[
            Token(text: "> ", type: .operator),
            Token(text: "collecting diagnostics ", type: .plain),
            Token(text: "[", type: .operator),
            Token(text: bar, type: .number),
            Token(text: "] ", type: .operator),
            Token(text: "\(percentage)", type: .number),
            Token(text: "% complete", type: .plain),
        ]]
    }

    /// Converts token lines into a syntax-highlighted NSAttributedString.
    private static func syntaxHighlight(_ tokenLines: [[Token]], fontSize: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = programmerFont(size: fontSize)
        let boldFont = programmerFont(size: fontSize, weight: .bold)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = fontSize * 0.45
        paragraphStyle.paragraphSpacing = 2

        for (lineIndex, line) in tokenLines.enumerated() {
            for token in line {
                let color: NSColor
                let tokenFont: NSFont
                var shadow: NSShadow?

                switch token.type {
                case .keyword:
                    color = neonPink
                    tokenFont = boldFont
                    shadow = makeGlow(color: neonPink, radius: 8)
                case .number:
                    color = electricCyan
                    tokenFont = font
                    shadow = makeGlow(color: electricCyan, radius: 5)
                case .string:
                    color = neonPurple
                    tokenFont = font
                    shadow = makeGlow(color: neonPurple, radius: 5)
                case .operator:
                    color = laserOrange
                    tokenFont = font
                    shadow = makeGlow(color: laserOrange, radius: 3)
                case .plain:
                    color = dimCyan
                    tokenFont = font
                    shadow = nil
                }

                var attrs: [NSAttributedString.Key: Any] = [
                    .font: tokenFont,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle,
                ]
                if let shadow = shadow {
                    attrs[.shadow] = shadow
                }

                result.append(NSAttributedString(string: token.text, attributes: attrs))
            }

            if lineIndex < tokenLines.count - 1 {
                let newline = NSAttributedString(string: "\n", attributes: [
                    .font: font,
                    .paragraphStyle: paragraphStyle,
                ])
                result.append(newline)
            }
        }

        return result
    }

    // MARK: - Helpers

    /// Creates an NSShadow configured as a neon glow effect.
    private static func makeGlow(color: NSColor, radius: CGFloat) -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = color.withAlphaComponent(0.8)
        shadow.shadowBlurRadius = radius
        shadow.shadowOffset = NSSize(width: 0, height: 0)
        return shadow
    }

    /// Clamps a font size computed from frame height to [min, max].
    private static func clampedFontSize(
        min minSize: CGFloat,
        max maxSize: CGFloat,
        fraction: CGFloat,
        frameHeight: CGFloat
    ) -> CGFloat {
        return Swift.min(maxSize, Swift.max(minSize, frameHeight * fraction))
    }

    /// Creates a small info label for the QR code area.
    private static func makeInfoLabel(
        text: String,
        fontSize: CGFloat,
        color: NSColor,
        width: CGFloat
    ) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = programmerFont(size: fontSize)
        label.textColor = color
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.preferredMaxLayoutWidth = width
        label.frame = NSRect(x: 0, y: 0, width: width, height: 0)
        label.sizeToFit()
        return label
    }

    /// Returns a random 8-character uppercase hex string (32 bits).
    private static func randomHex8() -> String {
        String(format: "%08X", UInt32.random(in: 0...UInt32.max))
    }

    /// Returns a random 4-character uppercase hex string (16 bits).
    private static func randomHexShort() -> String {
        String(format: "%04X", UInt16.random(in: 0...UInt16.max))
    }
}
