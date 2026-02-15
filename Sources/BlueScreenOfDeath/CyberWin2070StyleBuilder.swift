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

// MARK: - Background Element Type

/// The randomly selected background element for each render.
private enum BackgroundElement: CaseIterable {
    case mountains
    case outrunSun
    case perspectiveLines
    case skyscrapers
}

// MARK: - Wireframe Mountains View

/// Draws retro vector-style wireframe mountain ridgelines in electric blue/cyan.
/// Multiple layered ridgelines at different heights with perspective foreshortening.
private final class WireframeMountainsView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let horizonY = bounds.height * 0.55
        let baseY = bounds.height * 0.08

        // Draw 5 ridgelines from back (highest, dimmest) to front (lowest, brightest)
        let ridgeCount = 5
        for i in 0..<ridgeCount {
            let t = CGFloat(i) / CGFloat(ridgeCount - 1)  // 0 = farthest, 1 = nearest

            // Vertical position: back ridges are higher (near horizon), front ridges lower
            let ridgeBaseY = horizonY - t * (horizonY - baseY)

            // Peak height decreases for nearer ridges (perspective)
            let maxPeak = bounds.height * (0.30 - t * 0.12)

            // Alpha: back ridges are dimmer
            let alpha = 0.2 + t * 0.6

            // Line width: nearer ridges are thicker
            let lineWidth: CGFloat = 0.6 + t * 1.2

            // Color shifts from deep blue (far) to bright cyan (near)
            let blue = 0.7 + t * 0.3
            let green = 0.6 + t * 0.4
            let red = 0.0 + t * 0.15
            let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)

            // Generate the ridgeline path
            let path = NSBezierPath()

            // Use a deterministic-ish seed per ridge so it looks consistent within a frame
            // but changes between buildView calls (since arc4random is used)
            let segmentCount = Int.random(in: 18...28)
            let segmentWidth = bounds.width / CGFloat(segmentCount)

            // Start off-screen left
            path.move(to: NSPoint(x: -segmentWidth, y: ridgeBaseY))

            var points: [NSPoint] = []
            for s in 0...segmentCount + 1 {
                let x = CGFloat(s) * segmentWidth - segmentWidth * 0.5

                // Generate mountain-like height: use multiple sine waves for natural look
                let freq1 = CGFloat.random(in: 0.8...1.2)
                let freq2 = CGFloat.random(in: 1.5...2.5)
                let freq3 = CGFloat.random(in: 3.0...5.0)
                let phase1 = CGFloat(s) * freq1 * 0.3
                let phase2 = CGFloat(s) * freq2 * 0.3
                let phase3 = CGFloat(s) * freq3 * 0.3

                // Combine harmonics for natural mountain shape
                var height = sin(phase1) * 0.5 + sin(phase2) * 0.3 + sin(phase3) * 0.15

                // Clamp to positive (mountains go up from the base)
                height = max(0, height) * maxPeak

                // Taper toward edges
                let edgeFade = 1.0 - pow(abs(CGFloat(s) / CGFloat(segmentCount) - 0.5) * 2, 2)
                height *= edgeFade

                // Add some random jitter for craggy peaks
                height += CGFloat.random(in: 0...maxPeak * 0.08)

                points.append(NSPoint(x: x, y: ridgeBaseY + height))
            }

            // Draw the ridgeline through the points
            for (idx, pt) in points.enumerated() {
                if idx == 0 {
                    path.move(to: pt)
                } else {
                    path.line(to: pt)
                }
            }

            // Main line
            context.saveGState()
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)

            let cgPath = cgPathFromBezier(path)
            context.addPath(cgPath)
            context.strokePath()

            // Glow pass
            let glowColor = color.withAlphaComponent(alpha * 0.25)
            context.setStrokeColor(glowColor.cgColor)
            context.setLineWidth(lineWidth * 4)
            context.addPath(cgPath)
            context.strokePath()

            context.restoreGState()

            // Draw vertical wireframe lines from ridge down to base for front ridges
            if i >= ridgeCount - 2 {
                let wireAlpha = alpha * 0.15
                let wireColor = NSColor(red: red, green: green, blue: blue, alpha: wireAlpha)
                context.setStrokeColor(wireColor.cgColor)
                context.setLineWidth(0.4)

                let wireSpacing = bounds.width / CGFloat(Int.random(in: 14...22))
                var wx: CGFloat = 0
                while wx < bounds.width {
                    // Find the height at this x by interpolation
                    let segIdx = Int(wx / segmentWidth)
                    if segIdx < points.count - 1 {
                        let localT = (wx - CGFloat(segIdx) * segmentWidth) / segmentWidth
                        let y1 = points[segIdx].y
                        let y2 = points[segIdx + 1].y
                        let topY = y1 + (y2 - y1) * localT

                        context.move(to: CGPoint(x: wx, y: ridgeBaseY))
                        context.addLine(to: CGPoint(x: wx, y: topY))
                        context.strokePath()
                    }
                    wx += wireSpacing
                }
            }
        }

        // Horizon glow
        let glowColors = [
            NSColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.3).cgColor,
            NSColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.0).cgColor,
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1]) {
            context.saveGState()
            let center = CGPoint(x: bounds.midX, y: horizonY)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: bounds.width * 0.4,
                options: []
            )
            context.restoreGState()
        }
    }

    private func cgPathFromBezier(_ bezierPath: NSBezierPath) -> CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0..<bezierPath.elementCount {
            let element = bezierPath.element(at: i, associatedPoints: &points)
            switch element {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo, .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}

// MARK: - Outrun Sun View

/// Draws the classic retrowave striped semicircle sun with horizontal slices
/// and a warm-to-pink gradient, plus a glow effect.
private final class OutrunSunView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let centerX = bounds.midX
        let horizonY = bounds.height * 0.42
        let sunRadius = min(bounds.width, bounds.height) * 0.30

        // Outer glow behind the sun
        drawSunGlow(context: context, center: CGPoint(x: centerX, y: horizonY),
                     radius: sunRadius)

        // Draw the sun disc with gradient and stripe cutouts
        drawSunDisc(context: context, centerX: centerX, horizonY: horizonY,
                    radius: sunRadius)

        // Reflection lines below horizon
        drawReflection(context: context, centerX: centerX, horizonY: horizonY,
                       radius: sunRadius)
    }

    private func drawSunGlow(context: CGContext, center: CGPoint, radius: CGFloat) {
        let glowColors = [
            NSColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.35).cgColor,
            NSColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 0.15).cgColor,
            NSColor(red: 0.8, green: 0.1, blue: 0.6, alpha: 0.0).cgColor,
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: glowColors,
                                     locations: [0, 0.5, 1]) {
            context.saveGState()
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: radius * 0.3,
                endCenter: center,
                endRadius: radius * 2.2,
                options: []
            )
            context.restoreGState()
        }
    }

    private func drawSunDisc(context: CGContext, centerX: CGFloat, horizonY: CGFloat,
                             radius: CGFloat) {
        // Number of horizontal stripe gaps in the lower half
        let stripeCount = 8
        let stripeGapBase: CGFloat = radius * 0.015  // thinnest gap at top
        let stripeGrowth: CGFloat = radius * 0.008   // gaps grow toward bottom

        context.saveGState()

        // Clip to the full circle first
        context.addEllipse(in: CGRect(
            x: centerX - radius,
            y: horizonY - radius,
            width: radius * 2,
            height: radius * 2
        ))

        // Cut out horizontal stripes from bottom half of the circle
        // We use even-odd fill to subtract rectangles
        for i in 1...stripeCount {
            let t = CGFloat(i) / CGFloat(stripeCount + 1)
            let gapY = horizonY - t * radius  // goes down from center
            let gapHeight = stripeGapBase + CGFloat(i) * stripeGrowth

            // Add a rectangle that will be subtracted via even-odd
            context.addRect(CGRect(
                x: centerX - radius - 1,
                y: gapY - gapHeight / 2,
                width: radius * 2 + 2,
                height: gapHeight
            ))
        }

        context.clip(using: .evenOdd)

        // Now draw the gradient-filled disc
        let gradientColors = [
            NSColor(red: 1.0, green: 0.95, blue: 0.3, alpha: 1.0).cgColor,   // bright yellow top
            NSColor(red: 1.0, green: 0.65, blue: 0.1, alpha: 1.0).cgColor,   // warm orange
            NSColor(red: 1.0, green: 0.25, blue: 0.3, alpha: 1.0).cgColor,   // hot red-orange
            NSColor(red: 0.95, green: 0.1, blue: 0.5, alpha: 1.0).cgColor,   // hot pink bottom
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors,
                                     locations: [0, 0.35, 0.65, 1.0]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: centerX, y: horizonY + radius),
                end: CGPoint(x: centerX, y: horizonY - radius),
                options: []
            )
        }

        context.restoreGState()

        // Thin bright outline around the sun
        context.saveGState()
        context.setStrokeColor(NSColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 0.5).cgColor)
        context.setLineWidth(1.5)
        context.addEllipse(in: CGRect(
            x: centerX - radius,
            y: horizonY - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.strokePath()
        context.restoreGState()
    }

    private func drawReflection(context: CGContext, centerX: CGFloat, horizonY: CGFloat,
                                radius: CGFloat) {
        // Faint reflection lines below the horizon
        let reflectionCount = 12
        for i in 0..<reflectionCount {
            let t = CGFloat(i) / CGFloat(reflectionCount)
            let y = horizonY - radius * 0.1 - t * radius * 1.2
            let alpha = (1.0 - t) * 0.15
            let width = radius * (1.0 - t * 0.6) * 2

            // Color shifts from orange to pink going down
            let red: CGFloat = 1.0
            let green = 0.6 * (1.0 - t)
            let blue = 0.2 + t * 0.4

            context.setStrokeColor(NSColor(red: red, green: green, blue: blue, alpha: alpha).cgColor)
            context.setLineWidth(max(0.8, 2.0 * (1.0 - t)))
            context.move(to: CGPoint(x: centerX - width / 2, y: y))
            context.addLine(to: CGPoint(x: centerX + width / 2, y: y))
            context.strokePath()
        }
    }
}

// MARK: - Perspective Grid View (Full, for option C)

/// A custom NSView that draws a retrowave perspective grid converging toward a randomized
/// vanishing point. Line colors also vary between instantiations.
private final class PerspectiveGridView: NSView {

    /// The vanishing point position, randomized on init.
    let vanishingPointFraction: CGPoint

    /// Color hue for horizontal lines (0-1 range).
    let horizontalHue: CGFloat

    /// Color hue for vertical lines (0-1 range).
    let verticalHue: CGFloat

    init(frame: NSRect, vanishingPointFraction: CGPoint, horizontalHue: CGFloat,
         verticalHue: CGFloat) {
        self.vanishingPointFraction = vanishingPointFraction
        self.horizontalHue = horizontalHue
        self.verticalHue = verticalHue
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let vanishingPoint = NSPoint(
            x: bounds.width * vanishingPointFraction.x,
            y: bounds.height * vanishingPointFraction.y
        )
        let gridBottom: CGFloat = 0
        let gridTop = bounds.height
        let gridHeight = gridTop - gridBottom

        // Horizontal line color from hue
        let hColor = NSColor(hue: horizontalHue, saturation: 0.9, brightness: 1.0, alpha: 1.0)
        let hRed = hColor.redComponent
        let hGreen = hColor.greenComponent
        let hBlue = hColor.blueComponent

        // -- Horizontal lines (perspective-foreshortened) --
        let horizontalLineCount = 20
        for i in 0...horizontalLineCount {
            let t = CGFloat(i) / CGFloat(horizontalLineCount)
            let exponentialT = pow(t, 2.2)
            let y = gridBottom + exponentialT * gridHeight

            let alpha = max(0.05, 1.0 - pow(t, 0.8)) * 0.55
            let perspectiveFactor = 1.0 - (y - gridBottom) / gridHeight
            let halfWidth = (bounds.width * 0.7) * perspectiveFactor + bounds.width * 0.02

            let lineColor = NSColor(red: hRed, green: hGreen, blue: hBlue,
                                    alpha: alpha * 0.6)
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(max(0.5, 1.2 * (1.0 - t)))

            let path = NSBezierPath()
            path.move(to: NSPoint(x: vanishingPoint.x - halfWidth, y: y))
            path.line(to: NSPoint(x: vanishingPoint.x + halfWidth, y: y))
            path.stroke()

            // Glow pass
            let glowColor = NSColor(red: hRed, green: hGreen, blue: hBlue,
                                    alpha: alpha * 0.15)
            context.setStrokeColor(glowColor.cgColor)
            context.setLineWidth(max(1.5, 4.0 * (1.0 - t)))
            let glowPath = NSBezierPath()
            glowPath.move(to: NSPoint(x: vanishingPoint.x - halfWidth, y: y))
            glowPath.line(to: NSPoint(x: vanishingPoint.x + halfWidth, y: y))
            glowPath.stroke()
        }

        // Vertical line color from hue
        let vColor = NSColor(hue: verticalHue, saturation: 0.85, brightness: 1.0, alpha: 1.0)
        let vRed = vColor.redComponent
        let vGreen = vColor.greenComponent
        let vBlue = vColor.blueComponent

        // -- Vertical lines converging to vanishing point --
        let verticalLineCount = 24
        for i in 0...verticalLineCount {
            let t = CGFloat(i) / CGFloat(verticalLineCount)
            let bottomX = -bounds.width * 0.3 + t * bounds.width * 1.6

            let alpha: CGFloat = 0.35
            let lineColor = NSColor(red: vRed, green: vGreen, blue: vBlue,
                                    alpha: alpha * 0.5)

            let path = NSBezierPath()
            path.move(to: NSPoint(x: bottomX, y: gridBottom))
            path.line(to: vanishingPoint)

            context.saveGState()
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(0.8)
            path.stroke()

            let glowColor = NSColor(red: vRed, green: vGreen, blue: vBlue,
                                    alpha: alpha * 0.12)
            context.setStrokeColor(glowColor.cgColor)
            context.setLineWidth(3.0)
            path.stroke()

            context.restoreGState()
        }

        // -- Horizon glow at vanishing point --
        let glowHue = (horizontalHue + verticalHue) / 2
        let glowNSColor = NSColor(hue: glowHue, saturation: 0.8, brightness: 1.0, alpha: 1.0)
        let gradientColors = [
            glowNSColor.withAlphaComponent(0.35).cgColor,
            glowNSColor.withAlphaComponent(0.0).cgColor,
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors,
                                     locations: [0, 1]) {
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

// MARK: - Simple Ground Grid View (for non-grid background options)

/// A minimal perspective grid occupying just the bottom ~15% of the screen as a ground plane.
private final class SimpleGroundGridView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let vanishingPoint = NSPoint(x: bounds.midX, y: bounds.height)
        let gridBottom: CGFloat = 0
        let gridTop = bounds.height
        let gridHeight = gridTop - gridBottom

        // Horizontal lines
        let hLineCount = 10
        for i in 0...hLineCount {
            let t = CGFloat(i) / CGFloat(hLineCount)
            let exponentialT = pow(t, 2.0)
            let y = gridBottom + exponentialT * gridHeight

            let alpha = max(0.03, 1.0 - pow(t, 0.7)) * 0.4
            let perspectiveFactor = 1.0 - (y - gridBottom) / gridHeight
            let halfWidth = (bounds.width * 0.6) * perspectiveFactor + bounds.width * 0.02

            let lineColor = NSColor(red: 1.0, green: 0.16, blue: 0.46, alpha: alpha * 0.5)
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(max(0.4, 0.9 * (1.0 - t)))

            context.move(to: CGPoint(x: vanishingPoint.x - halfWidth, y: y))
            context.addLine(to: CGPoint(x: vanishingPoint.x + halfWidth, y: y))
            context.strokePath()
        }

        // Vertical lines
        let vLineCount = 16
        for i in 0...vLineCount {
            let t = CGFloat(i) / CGFloat(vLineCount)
            let bottomX = -bounds.width * 0.2 + t * bounds.width * 1.4

            let lineColor = NSColor(red: 0.0, green: 1.0, blue: 0.96, alpha: 0.12)
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(0.5)

            context.move(to: CGPoint(x: bottomX, y: gridBottom))
            context.addLine(to: CGPoint(x: vanishingPoint.x, y: gridTop))
            context.strokePath()
        }
    }
}

// MARK: - Cyberpunk Skyscrapers View

/// Draws a procedural pink/magenta cyberpunk cityscape silhouette with glowing windows.
private final class CyberpunkSkyscrapersView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let cityBottom: CGFloat = 0
        let maxBuildingHeight = bounds.height * 0.85

        // City glow: faint pink ambient light behind the skyline
        drawCityGlow(context: context)

        // Generate and draw buildings from back to front in layers
        drawBuildingLayer(context: context, count: Int.random(in: 20...30),
                          minHeight: maxBuildingHeight * 0.3, maxHeight: maxBuildingHeight,
                          baseY: cityBottom,
                          color: NSColor(red: 0.25, green: 0.02, blue: 0.18, alpha: 0.85),
                          windowBrightness: 0.15, drawAntennas: true)

        drawBuildingLayer(context: context, count: Int.random(in: 16...24),
                          minHeight: maxBuildingHeight * 0.15, maxHeight: maxBuildingHeight * 0.65,
                          baseY: cityBottom,
                          color: NSColor(red: 0.45, green: 0.04, blue: 0.30, alpha: 0.9),
                          windowBrightness: 0.25, drawAntennas: true)

        drawBuildingLayer(context: context, count: Int.random(in: 12...20),
                          minHeight: maxBuildingHeight * 0.1, maxHeight: maxBuildingHeight * 0.45,
                          baseY: cityBottom,
                          color: NSColor(red: 0.65, green: 0.05, blue: 0.40, alpha: 0.95),
                          windowBrightness: 0.4, drawAntennas: false)
    }

    private func drawCityGlow(context: CGContext) {
        let glowColors = [
            NSColor(red: 0.9, green: 0.1, blue: 0.5, alpha: 0.2).cgColor,
            NSColor(red: 0.6, green: 0.05, blue: 0.35, alpha: 0.08).cgColor,
            NSColor(red: 0.4, green: 0.02, blue: 0.25, alpha: 0.0).cgColor,
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: glowColors,
                                     locations: [0, 0.5, 1.0]) {
            context.saveGState()
            let center = CGPoint(x: bounds.midX, y: bounds.height * 0.3)
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: bounds.width * 0.6,
                options: []
            )
            context.restoreGState()
        }
    }

    private func drawBuildingLayer(context: CGContext, count: Int,
                                   minHeight: CGFloat, maxHeight: CGFloat,
                                   baseY: CGFloat, color: NSColor,
                                   windowBrightness: CGFloat, drawAntennas: Bool) {
        var x: CGFloat = -CGFloat.random(in: 0...20)

        for _ in 0..<count {
            let buildingWidth = CGFloat.random(in: bounds.width * 0.025...bounds.width * 0.08)
            let buildingHeight = CGFloat.random(in: minHeight...maxHeight)
            let gap = CGFloat.random(in: 0...bounds.width * 0.008)

            // Building body
            let buildingRect = CGRect(x: x, y: baseY, width: buildingWidth, height: buildingHeight)
            context.setFillColor(color.cgColor)
            context.fill(buildingRect)

            // Top features: sometimes a stepped top, sometimes flat, sometimes pointed
            let topStyle = Int.random(in: 0...4)
            switch topStyle {
            case 0:
                // Stepped / tiered top
                let tierWidth = buildingWidth * CGFloat.random(in: 0.4...0.7)
                let tierHeight = CGFloat.random(in: buildingHeight * 0.03...buildingHeight * 0.1)
                let tierRect = CGRect(
                    x: x + (buildingWidth - tierWidth) / 2,
                    y: baseY + buildingHeight,
                    width: tierWidth,
                    height: tierHeight
                )
                context.fill(tierRect)

                // Sometimes a second smaller tier
                if Bool.random() {
                    let tier2Width = tierWidth * 0.5
                    let tier2Height = tierHeight * 0.7
                    let tier2Rect = CGRect(
                        x: x + (buildingWidth - tier2Width) / 2,
                        y: baseY + buildingHeight + tierHeight,
                        width: tier2Width,
                        height: tier2Height
                    )
                    context.fill(tier2Rect)
                }
            case 1 where drawAntennas:
                // Antenna spire
                let antennaHeight = CGFloat.random(in: buildingHeight * 0.05...buildingHeight * 0.2)
                let antennaWidth: CGFloat = max(1, buildingWidth * 0.03)
                context.setStrokeColor(color.cgColor)
                context.setLineWidth(antennaWidth)
                let antennaX = x + buildingWidth * CGFloat.random(in: 0.3...0.7)
                context.move(to: CGPoint(x: antennaX, y: baseY + buildingHeight))
                context.addLine(to: CGPoint(x: antennaX, y: baseY + buildingHeight + antennaHeight))
                context.strokePath()

                // Blinking light at tip
                let tipColor = Bool.random()
                    ? NSColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 0.9)
                    : NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9)
                let tipSize: CGFloat = max(2, buildingWidth * 0.04)
                context.setFillColor(tipColor.cgColor)
                context.fillEllipse(in: CGRect(
                    x: antennaX - tipSize / 2,
                    y: baseY + buildingHeight + antennaHeight - tipSize / 2,
                    width: tipSize,
                    height: tipSize
                ))
            case 2:
                // Slanted roof
                let roofHeight = CGFloat.random(in: buildingHeight * 0.02...buildingHeight * 0.06)
                context.move(to: CGPoint(x: x, y: baseY + buildingHeight))
                context.addLine(to: CGPoint(x: x + buildingWidth, y: baseY + buildingHeight))
                context.addLine(to: CGPoint(
                    x: x + buildingWidth * CGFloat.random(in: 0.3...0.7),
                    y: baseY + buildingHeight + roofHeight
                ))
                context.closePath()
                context.fillPath()
            default:
                break  // Flat top
            }

            // Windows
            let windowSize = max(1.5, buildingWidth * 0.08)
            let windowSpacingX = windowSize * CGFloat.random(in: 2.0...3.5)
            let windowSpacingY = windowSize * CGFloat.random(in: 2.5...4.0)
            let windowMargin = buildingWidth * 0.12

            // Choose a window pattern for this building
            let windowPattern = Int.random(in: 0...2)

            var wy = baseY + windowMargin
            while wy < baseY + buildingHeight - windowMargin {
                var wx = x + windowMargin
                while wx < x + buildingWidth - windowMargin {
                    // Some windows are lit, some dark
                    let isLit: Bool
                    switch windowPattern {
                    case 0: isLit = Bool.random()                    // random scatter
                    case 1: isLit = Int(wy / windowSpacingY) % 2 == 0  // alternating rows
                    default: isLit = CGFloat.random(in: 0...1) < 0.35  // sparse
                    }

                    if isLit {
                        let brightness = windowBrightness * CGFloat.random(in: 0.6...1.0)
                        // Window colors: mostly warm yellow/white, occasional cyan or pink
                        let windowColor: NSColor
                        let colorRoll = CGFloat.random(in: 0...1)
                        if colorRoll < 0.7 {
                            windowColor = NSColor(red: 1.0, green: 0.9, blue: 0.6,
                                                  alpha: brightness)
                        } else if colorRoll < 0.85 {
                            windowColor = NSColor(red: 0.3, green: 0.9, blue: 1.0,
                                                  alpha: brightness * 0.8)
                        } else {
                            windowColor = NSColor(red: 1.0, green: 0.3, blue: 0.6,
                                                  alpha: brightness * 0.7)
                        }
                        context.setFillColor(windowColor.cgColor)
                        context.fill(CGRect(x: wx, y: wy, width: windowSize,
                                            height: windowSize * 1.3))
                    }
                    wx += windowSpacingX
                }
                wy += windowSpacingY
            }

            // Building edge highlight (left side)
            let edgeColor = NSColor(red: 0.9, green: 0.1, blue: 0.5, alpha: 0.12)
            context.setStrokeColor(edgeColor.cgColor)
            context.setLineWidth(0.8)
            context.move(to: CGPoint(x: x, y: baseY))
            context.addLine(to: CGPoint(x: x, y: baseY + buildingHeight))
            context.strokePath()

            x += buildingWidth + gap
            if x > bounds.width + 10 { break }
        }
    }
}

// MARK: - CyberWin 2070 Style Builder

/// Builds the CyberWin 2070 themed BSOD view.
///
/// This produces a retro-futuristic terminal-style crash screen with neon colors,
/// CRT scan lines, a randomly-selected procedural background element, and
/// randomly-generated fake stack traces styled like syntax-highlighted terminal output.
struct CyberWin2070StyleBuilder {

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

    /// Build the CyberWin 2070 themed view for the given frame.
    /// The view is fully self-contained and works at any size (full-screen or preview).
    /// Each call randomly selects one of four background elements.
    static func buildView(frame: NSRect) -> NSView {
        let container = NSView(frame: frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = darkBg.cgColor

        // 1. Background gradient layer (subtle vignette)
        addBackgroundGradient(to: container)

        // 2. Randomly select exactly one background element
        let element = BackgroundElement.allCases.randomElement()!
        addBackgroundElement(element, to: container, frame: frame)

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

    // MARK: - Background Element Selection

    private static func addBackgroundElement(_ element: BackgroundElement,
                                             to container: NSView, frame: NSRect) {
        switch element {
        case .mountains:
            // Mountains fill middle area; simple ground grid at very bottom
            let groundHeight = frame.height * 0.15
            let groundGrid = SimpleGroundGridView(frame: NSRect(
                x: 0, y: 0, width: frame.width, height: groundHeight
            ))
            container.addSubview(groundGrid)

            let mountainsView = WireframeMountainsView(frame: NSRect(
                x: 0, y: 0, width: frame.width, height: frame.height * 0.55
            ))
            container.addSubview(mountainsView)

        case .outrunSun:
            // Simple ground grid at very bottom
            let groundHeight = frame.height * 0.15
            let groundGrid = SimpleGroundGridView(frame: NSRect(
                x: 0, y: 0, width: frame.width, height: groundHeight
            ))
            container.addSubview(groundGrid)

            // Sun occupies upper-middle area
            let sunView = OutrunSunView(frame: NSRect(
                x: 0, y: frame.height * 0.10, width: frame.width, height: frame.height * 0.55
            ))
            container.addSubview(sunView)

        case .perspectiveLines:
            // Full perspective grid with randomized vanishing point and colors
            let vanishingPoints: [CGPoint] = [
                CGPoint(x: 0.5, y: 1.0),     // center-top (classic)
                CGPoint(x: 0.25, y: 0.95),   // left-high
                CGPoint(x: 0.75, y: 0.95),   // right-high
                CGPoint(x: 0.35, y: 0.80),   // left-low
                CGPoint(x: 0.65, y: 0.80),   // right-low
                CGPoint(x: 0.5, y: 0.75),    // center-low
                CGPoint(x: 0.15, y: 0.90),   // far left
                CGPoint(x: 0.85, y: 0.90),   // far right
            ]
            let chosenVP = vanishingPoints.randomElement()!

            // Randomize line colors
            let hHue = CGFloat.random(in: 0...1)     // any hue for horizontal
            let vHue = CGFloat.random(in: 0...1)     // any hue for vertical

            let gridHeight = frame.height * 0.28
            let gridView = PerspectiveGridView(
                frame: NSRect(x: 0, y: 0, width: frame.width, height: gridHeight),
                vanishingPointFraction: chosenVP,
                horizontalHue: hHue,
                verticalHue: vHue
            )
            container.addSubview(gridView)

        case .skyscrapers:
            // Simple ground grid at very bottom
            let groundHeight = frame.height * 0.15
            let groundGrid = SimpleGroundGridView(frame: NSRect(
                x: 0, y: 0, width: frame.width, height: groundHeight
            ))
            container.addSubview(groundGrid)

            // Cityscape in the bottom portion
            let cityHeight = frame.height * 0.40
            let cityView = CyberpunkSkyscrapersView(frame: NSRect(
                x: 0, y: 0, width: frame.width, height: cityHeight
            ))
            container.addSubview(cityView)
        }
    }

    // MARK: - Foreground Content

    private static func addForegroundContent(to container: NSView, frame: NSRect) {
        let leftMargin = frame.width * 0.12
        let maxTextWidth = frame.width * 0.65
        var yOffset = frame.height * 0.80

        // -- Sad face emoticon: :( -- styled with neon pink glow
        let sadFaceSize = min(150, frame.height * 0.2)
        let sadFaceLabel = NSTextField(labelWithString: ":(")
        sadFaceLabel.font = NSFont.systemFont(ofSize: sadFaceSize, weight: .light)
        sadFaceLabel.textColor = neonPink
        sadFaceLabel.backgroundColor = .clear
        sadFaceLabel.isBezeled = false
        sadFaceLabel.isEditable = false
        sadFaceLabel.shadow = makeGlow(color: neonPink, radius: 18)
        sadFaceLabel.sizeToFit()
        sadFaceLabel.frame.origin = NSPoint(x: leftMargin, y: yOffset - sadFaceLabel.frame.height)
        container.addSubview(sadFaceLabel)

        // Extra glow layer behind the emoticon for bloom effect
        let sadFaceGlow = NSTextField(labelWithString: ":(")
        sadFaceGlow.font = NSFont.systemFont(ofSize: sadFaceSize, weight: .light)
        sadFaceGlow.textColor = neonPink.withAlphaComponent(0.3)
        sadFaceGlow.backgroundColor = .clear
        sadFaceGlow.isBezeled = false
        sadFaceGlow.isEditable = false
        sadFaceGlow.shadow = makeGlow(color: neonPink, radius: 40)
        sadFaceGlow.sizeToFit()
        sadFaceGlow.frame.origin = sadFaceLabel.frame.origin
        container.addSubview(sadFaceGlow, positioned: .below, relativeTo: sadFaceLabel)

        yOffset -= sadFaceLabel.frame.height + frame.height * 0.03

        // -- Body: syntax-highlighted fake stack trace --
        let bodyFontSize = clampedFontSize(min: 10.0, max: 16.0, fraction: 0.018,
                                           frameHeight: frame.height)
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
        let progressFontSize = clampedFontSize(min: 10.0, max: 14.0, fraction: 0.016,
                                               frameHeight: frame.height)
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
            let infoFontSize = clampedFontSize(min: 8.0, max: 11.0, fraction: 0.013,
                                               frameHeight: frame.height)

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
        let bar = String(repeating: "=", count: filled)
            + ">"
            + String(repeating: " ", count: max(0, empty - 1))
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
    private static func syntaxHighlight(_ tokenLines: [[Token]],
                                        fontSize: CGFloat) -> NSAttributedString {
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
