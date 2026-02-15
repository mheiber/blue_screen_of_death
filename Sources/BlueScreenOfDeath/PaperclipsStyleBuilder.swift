import AppKit

// MARK: - Paperclips (Dali Surrealist) Style Builder

/// Builds a Salvador Dali-inspired surrealist BSOD scene featuring melting paperclips
/// draped across a warm desert landscape. Think "The Persistence of Memory" but with
/// paperclips instead of clocks. Every render is procedurally unique.
struct PaperclipsStyleBuilder {

    /// Deep indigo for the top of the sky
    static let skyTop = NSColor(red: 0.106, green: 0.078, blue: 0.392, alpha: 1.0)       // #1B1464

    /// Warm amber for the horizon glow
    static let skyHorizon = NSColor(red: 0.961, green: 0.651, blue: 0.137, alpha: 1.0)    // #F5A623

    /// Warm sand for the desert floor
    static let desertSand = NSColor(red: 0.831, green: 0.647, blue: 0.455, alpha: 1.0)    // #D4A574

    /// Deep shadow for the desert
    static let desertShadow = NSColor(red: 0.545, green: 0.424, blue: 0.259, alpha: 1.0)  // #8B6C42

    /// Warm dark brown for cast shadows
    static let warmShadow = NSColor(red: 0.239, green: 0.169, blue: 0.122, alpha: 1.0)    // #3D2B1F

    // MARK: - Public Entry Point

    /// Build the Dali-inspired surrealist paperclips view for the given frame.
    static func buildView(frame: NSRect) -> NSView {
        let sceneData = SceneData(frame: frame)
        let view = DaliPaperclipsView(frame: frame, sceneData: sceneData)
        return view
    }
}

// MARK: - Scene Data (Randomized Once Per Render)

/// Pre-generated random data so the scene is consistent within a single draw pass
/// but different each time the view is created.
private struct PaperclipData {
    let centerX: CGFloat      // Normalized 0-1
    let centerY: CGFloat      // Normalized 0-1
    let scale: CGFloat         // Size multiplier
    let rotation: CGFloat      // Radians
    let meltFactor: CGFloat    // 0 = rigid, 1 = very melted
    let drapeFactor: CGFloat   // How much it drapes over an edge
    let drapeEdgeY: CGFloat    // Normalized Y of the invisible edge to drape over
    let wireThickness: CGFloat
    let hueShift: CGFloat      // Slight color variation for metallic sheen
    let waviness: CGFloat      // Sinusoidal wave amplitude for melt effect
    let waveFrequency: CGFloat // Frequency of the melt waviness
}

private struct FloatingShapeData {
    enum ShapeType { case circle, triangle, diamond, crescent }
    let type: ShapeType
    let centerX: CGFloat
    let centerY: CGFloat
    let size: CGFloat
    let opacity: CGFloat
}

private struct SceneData {
    let paperclips: [PaperclipData]
    let floatingShape: FloatingShapeData
    let showCheckerboard: Bool
    let shadowAngle: CGFloat           // Radians from vertical
    let shadowCount: Int
    let stopCode: String
    let hazeIntensity: CGFloat         // 0-1 atmospheric haze at horizon

    init(frame: NSRect) {
        let clipCount = Int.random(in: 5...8)
        var clips: [PaperclipData] = []

        for i in 0..<clipCount {
            let isBackground = i < 2
            let isForeground = i >= clipCount - 2
            let baseScale: CGFloat = isBackground ? CGFloat.random(in: 0.3...0.5) :
                                     (isForeground ? CGFloat.random(in: 0.9...1.4) :
                                     CGFloat.random(in: 0.5...0.9))

            clips.append(PaperclipData(
                centerX: CGFloat.random(in: 0.08...0.92),
                centerY: CGFloat.random(in: 0.15...0.65),
                scale: baseScale,
                rotation: CGFloat.random(in: -0.5...0.5),
                meltFactor: CGFloat.random(in: 0.3...1.0),
                drapeFactor: Bool.random() ? CGFloat.random(in: 0.2...0.8) : 0,
                drapeEdgeY: CGFloat.random(in: 0.25...0.55),
                wireThickness: CGFloat.random(in: 3.0...5.0),
                hueShift: CGFloat.random(in: -0.05...0.05),
                waviness: CGFloat.random(in: 5.0...20.0),
                waveFrequency: CGFloat.random(in: 0.02...0.06)
            ))
        }

        // Sort by scale so smaller (background) clips are drawn first
        self.paperclips = clips.sorted { $0.scale < $1.scale }

        let shapeTypes: [FloatingShapeData.ShapeType] = [.circle, .triangle, .diamond, .crescent]
        self.floatingShape = FloatingShapeData(
            type: shapeTypes.randomElement()!,
            centerX: CGFloat.random(in: 0.15...0.85),
            centerY: CGFloat.random(in: 0.72...0.92),
            size: CGFloat.random(in: 0.025...0.06),
            opacity: CGFloat.random(in: 0.3...0.6)
        )

        self.showCheckerboard = Bool.random()
        self.shadowAngle = CGFloat.random(in: -0.4...0.4)
        self.shadowCount = Int.random(in: 3...6)
        self.stopCode = CrashDumpGenerator.generateModernData().stopCode
        self.hazeIntensity = CGFloat.random(in: 0.15...0.4)
    }
}

// MARK: - Custom Drawing View

private final class DaliPaperclipsView: NSView {
    private let sceneData: SceneData

    init(frame: NSRect, sceneData: SceneData) {
        self.sceneData = sceneData
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        drawSky(in: context)
        drawDesert(in: context)
        drawCheckerboard(in: context)
        drawLongShadows(in: context)
        drawPaperclips(in: context)
        drawFloatingShape(in: context)
        drawAtmosphericHaze(in: context)
        drawStopCodeText(in: context)
    }

    // MARK: - Sky

    private var horizonY: CGFloat {
        bounds.height * 0.35
    }

    private func drawSky(in context: CGContext) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Multi-stop gradient: deep indigo at top -> purple midtone -> warm amber at horizon
        let colors = [
            CGColor(red: 0.106, green: 0.078, blue: 0.392, alpha: 1.0),  // Deep indigo #1B1464
            CGColor(red: 0.180, green: 0.110, blue: 0.450, alpha: 1.0),  // Mid indigo
            CGColor(red: 0.350, green: 0.150, blue: 0.420, alpha: 1.0),  // Purple transition
            CGColor(red: 0.600, green: 0.250, blue: 0.300, alpha: 1.0),  // Warm mauve
            CGColor(red: 0.850, green: 0.450, blue: 0.180, alpha: 1.0),  // Deep amber
            CGColor(red: 0.961, green: 0.651, blue: 0.137, alpha: 1.0),  // Warm amber #F5A623
            CGColor(red: 0.980, green: 0.780, blue: 0.350, alpha: 1.0),  // Light amber at horizon
        ] as CFArray

        let locations: [CGFloat] = [0.0, 0.2, 0.4, 0.55, 0.75, 0.9, 1.0]

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }

        context.saveGState()
        context.clip(to: CGRect(x: 0, y: horizonY, width: bounds.width, height: bounds.height - horizonY))
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: bounds.midX, y: bounds.height),
            end: CGPoint(x: bounds.midX, y: horizonY),
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()

        // Subtle sun glow near horizon
        drawSunGlow(in: context)
    }

    private func drawSunGlow(in context: CGContext) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let sunCenter = CGPoint(x: bounds.width * 0.65, y: horizonY + bounds.height * 0.02)

        let glowColors = [
            CGColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 0.35),
            CGColor(red: 1.0, green: 0.70, blue: 0.3, alpha: 0.15),
            CGColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 0.0),
        ] as CFArray
        let glowLocations: [CGFloat] = [0.0, 0.4, 1.0]

        guard let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: glowLocations) else { return }

        context.saveGState()
        context.drawRadialGradient(
            glow,
            startCenter: sunCenter,
            startRadius: 0,
            endCenter: sunCenter,
            endRadius: bounds.width * 0.35,
            options: []
        )
        context.restoreGState()
    }

    // MARK: - Desert

    private func drawDesert(in context: CGContext) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Desert gradient: lighter at horizon, darker warm sand in foreground
        let colors = [
            CGColor(red: 0.900, green: 0.750, blue: 0.580, alpha: 1.0),  // Light sand at horizon
            CGColor(red: 0.831, green: 0.647, blue: 0.455, alpha: 1.0),  // Mid sand #D4A574
            CGColor(red: 0.700, green: 0.530, blue: 0.360, alpha: 1.0),  // Deeper sand
            CGColor(red: 0.545, green: 0.424, blue: 0.259, alpha: 1.0),  // Shadow sand #8B6C42
        ] as CFArray

        let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }

        context.saveGState()
        context.clip(to: CGRect(x: 0, y: 0, width: bounds.width, height: horizonY))
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: bounds.midX, y: horizonY),
            end: CGPoint(x: bounds.midX, y: 0),
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }

    // MARK: - Checkerboard Floor

    private func drawCheckerboard(in context: CGContext) {
        guard sceneData.showCheckerboard else { return }

        let vanishX = bounds.width * 0.5
        let vanishY = horizonY
        let tileCountX = 16
        let tileCountZ = 20

        context.saveGState()
        context.clip(to: CGRect(x: 0, y: 0, width: bounds.width, height: horizonY))

        for row in 0..<tileCountZ {
            let t0 = CGFloat(row) / CGFloat(tileCountZ)
            let t1 = CGFloat(row + 1) / CGFloat(tileCountZ)

            // Exponential distribution to bunch rows near the horizon
            let perspT0 = pow(t0, 2.5)
            let perspT1 = pow(t1, 2.5)

            let y0 = vanishY - perspT0 * vanishY
            let y1 = vanishY - perspT1 * vanishY

            // Width expands as we come toward the viewer
            let halfWidth0 = bounds.width * 0.02 + (1.0 - t0) * bounds.width * 0.8
            let halfWidth1 = bounds.width * 0.02 + (1.0 - t1) * bounds.width * 0.8

            for col in 0..<tileCountX {
                let cx0 = CGFloat(col) / CGFloat(tileCountX)
                let cx1 = CGFloat(col + 1) / CGFloat(tileCountX)

                let isDark = (row + col) % 2 == 0
                let alpha: CGFloat = isDark ? 0.06 : 0.03

                // Fade out near horizon
                let fadeAlpha = alpha * (1.0 - pow(t0, 0.5)) * 0.8

                if fadeAlpha < 0.005 { continue }

                let leftTop = CGPoint(x: vanishX - halfWidth0 + cx0 * halfWidth0 * 2, y: y0)
                let rightTop = CGPoint(x: vanishX - halfWidth0 + cx1 * halfWidth0 * 2, y: y0)
                let rightBot = CGPoint(x: vanishX - halfWidth1 + cx1 * halfWidth1 * 2, y: y1)
                let leftBot = CGPoint(x: vanishX - halfWidth1 + cx0 * halfWidth1 * 2, y: y1)

                context.setFillColor(CGColor(red: 0.239, green: 0.169, blue: 0.122, alpha: fadeAlpha))
                context.beginPath()
                context.move(to: leftTop)
                context.addLine(to: rightTop)
                context.addLine(to: rightBot)
                context.addLine(to: leftBot)
                context.closePath()
                context.fillPath()
            }
        }

        context.restoreGState()
    }

    // MARK: - Long Shadows

    private func drawLongShadows(in context: CGContext) {
        context.saveGState()
        context.clip(to: CGRect(x: 0, y: 0, width: bounds.width, height: horizonY))

        let angle = sceneData.shadowAngle
        for i in 0..<sceneData.shadowCount {
            let t = CGFloat(i) / CGFloat(max(1, sceneData.shadowCount - 1))
            let startX = bounds.width * (0.1 + t * 0.8)
            let startY = horizonY * CGFloat.random(in: 0.1...0.4)

            let length = bounds.width * CGFloat.random(in: 0.3...0.7)
            let endX = startX + length * sin(angle)
            let endY = startY + length * cos(angle) * 0.15  // Very flat shadows

            let shadowAlpha = CGFloat.random(in: 0.04...0.10)

            context.setStrokeColor(CGColor(red: 0.239, green: 0.169, blue: 0.122, alpha: shadowAlpha))
            context.setLineWidth(CGFloat.random(in: 1.5...4.0))
            context.setLineCap(.round)
            context.beginPath()
            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()
        }

        context.restoreGState()
    }

    // MARK: - Paperclips (THE STAR)

    private func drawPaperclips(in context: CGContext) {
        for clip in sceneData.paperclips {
            drawSinglePaperclip(clip, in: context)
        }
    }

    /// Generates the raw points of a classic paperclip shape (two nested rounded rectangles
    /// connected at one end), then applies a melting warp, then renders with metallic gradient.
    private func drawSinglePaperclip(_ clip: PaperclipData, in context: CGContext) {
        // Base paperclip dimensions (before scaling)
        let baseWidth: CGFloat = 30
        let baseHeight: CGFloat = 80

        let scaledWidth = baseWidth * clip.scale
        let scaledHeight = baseHeight * clip.scale

        // Center position in view coordinates
        let cx = bounds.width * clip.centerX
        let cy = bounds.height * clip.centerY

        // Generate the path points for a classic paperclip shape
        let path = generateMeltedPaperclipPath(
            centerX: cx,
            centerY: cy,
            width: scaledWidth,
            height: scaledHeight,
            rotation: clip.rotation,
            meltFactor: clip.meltFactor,
            drapeFactor: clip.drapeFactor,
            drapeEdgeY: bounds.height * clip.drapeEdgeY,
            waviness: clip.waviness,
            waveFrequency: clip.waveFrequency
        )

        // Draw shadow first
        drawPaperclipShadow(path: path, thickness: clip.wireThickness * clip.scale, in: context)

        // Draw the metallic paperclip
        drawMetallicPaperclip(
            path: path,
            thickness: clip.wireThickness * clip.scale,
            hueShift: clip.hueShift,
            in: context
        )
    }

    /// Generates the bezier path for a melting paperclip.
    ///
    /// A paperclip is essentially: two parallel rails connected by a tight U-turn at the bottom
    /// and a wider U-turn at the top, with the inner rail shorter than the outer rail.
    /// The "melt" transform progressively pulls lower points downward and adds sinusoidal waviness.
    private func generateMeltedPaperclipPath(
        centerX: CGFloat,
        centerY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        rotation: CGFloat,
        meltFactor: CGFloat,
        drapeFactor: CGFloat,
        drapeEdgeY: CGFloat,
        waviness: CGFloat,
        waveFrequency: CGFloat
    ) -> CGMutablePath {

        let path = CGMutablePath()

        // Define the paperclip as a sequence of points forming the wire path.
        // The wire traces: up the left outer side, around the top, down the right outer side,
        // around the bottom, up the right inner side, around the inner top, down the left inner side.

        let halfW = width / 2.0
        let innerHalfW = halfW * 0.55  // Inner rail is narrower
        let topY = height * 0.5
        let botY = -height * 0.5
        let innerTopY = topY - height * 0.18  // Inner rail doesn't reach as high

        // We'll build the path as a series of segments. Each point is in local coordinates
        // centered at (0,0), then we transform for rotation, position, and melt.

        // The wire path of a paperclip (tracing the single wire):
        // Start at bottom-left of outer loop
        var rawPoints: [(x: CGFloat, y: CGFloat)] = []

        // Outer left side going up
        let outerLeftSteps = 12
        for i in 0...outerLeftSteps {
            let t = CGFloat(i) / CGFloat(outerLeftSteps)
            rawPoints.append((x: -halfW, y: botY + t * (topY - botY)))
        }

        // Top outer curve (semicircle from left to right)
        let topCurveSteps = 10
        for i in 1...topCurveSteps {
            let angle = CGFloat.pi - CGFloat.pi * CGFloat(i) / CGFloat(topCurveSteps)
            rawPoints.append((x: halfW * cos(angle), y: topY + halfW * sin(angle) * 0.3))
        }

        // Outer right side going down
        for i in 0...outerLeftSteps {
            let t = CGFloat(i) / CGFloat(outerLeftSteps)
            rawPoints.append((x: halfW, y: topY - t * (topY - botY)))
        }

        // Bottom outer curve (semicircle from right to left, tighter)
        let botCurveSteps = 8
        let botCurveRadius = halfW * 0.7
        for i in 1..<botCurveSteps {
            let angle = -CGFloat.pi / 2 + CGFloat.pi * CGFloat(i) / CGFloat(botCurveSteps)
            let px = botCurveRadius * cos(angle)
            let py = botY + botCurveRadius * sin(angle) * 0.4 - botCurveRadius * 0.3
            rawPoints.append((x: px, y: py))
        }

        // Inner right side going up
        let innerSteps = 10
        for i in 0...innerSteps {
            let t = CGFloat(i) / CGFloat(innerSteps)
            rawPoints.append((x: innerHalfW, y: botY + t * (innerTopY - botY)))
        }

        // Top inner curve (semicircle from right to left, smaller)
        for i in 1...topCurveSteps {
            let angle = CGFloat.pi * CGFloat(i) / CGFloat(topCurveSteps)
            rawPoints.append((x: innerHalfW * cos(angle), y: innerTopY + innerHalfW * sin(angle) * 0.25))
        }

        // Inner left side going down (back to start area)
        for i in 0...innerSteps {
            let t = CGFloat(i) / CGFloat(innerSteps)
            rawPoints.append((x: -innerHalfW, y: innerTopY - t * (innerTopY - botY) * 0.7))
        }

        // Now apply transforms: rotation, melt, drape, then translate to position
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let meltGravity = height * meltFactor * 0.6

        var transformed: [CGPoint] = []
        for pt in rawPoints {
            // Rotate
            var rx = pt.x * cosR - pt.y * sinR
            var ry = pt.x * sinR + pt.y * cosR

            // Melt: points lower in the shape droop more
            // Normalize y position: -1 at bottom, +1 at top (in local space before rotation)
            let normalizedY = (pt.y - botY) / (topY - botY)  // 0 at bottom, 1 at top
            let meltAmount = (1.0 - normalizedY) * meltGravity
            ry -= meltAmount

            // Add sinusoidal waviness to the drooping portions
            let wavePhase = pt.x * waveFrequency + normalizedY * 2.0
            let waveAmount = waviness * (1.0 - normalizedY) * meltFactor
            ry += sin(wavePhase) * waveAmount
            rx += cos(wavePhase * 0.7) * waveAmount * 0.3

            // Drape over edge: if the clip is near the drape edge, add extra droop below it
            if drapeFactor > 0 {
                let worldY = centerY + ry
                if worldY < drapeEdgeY {
                    let below = drapeEdgeY - worldY
                    ry -= below * drapeFactor * 0.5
                    // Also pull the point slightly outward for a natural drape
                    rx += rx.sign == .minus ? -below * drapeFactor * 0.1 : below * drapeFactor * 0.1
                }
            }

            // Translate to world position
            transformed.append(CGPoint(x: centerX + rx, y: centerY + ry))
        }

        // Build the CGPath using smooth curves through the transformed points
        guard transformed.count >= 3 else { return path }

        path.move(to: transformed[0])
        // Use Catmull-Rom to bezier conversion for smooth curves
        for i in 1..<transformed.count - 1 {
            let p0 = transformed[max(0, i - 1)]
            let p1 = transformed[i]
            let p2 = transformed[min(transformed.count - 1, i + 1)]

            let controlX = p1.x + (p2.x - p0.x) / 6.0
            let controlY = p1.y + (p2.y - p0.y) / 6.0
            let control2X = p2.x - (p2.x - p0.x) / 6.0
            let control2Y = p2.y - (p2.y - p0.y) / 6.0

            path.addCurve(
                to: p2,
                control1: CGPoint(x: controlX, y: controlY),
                control2: CGPoint(x: control2X, y: control2Y)
            )
        }

        return path
    }

    /// Draws a soft shadow beneath the paperclip path.
    private func drawPaperclipShadow(path: CGPath, thickness: CGFloat, in context: CGContext) {
        context.saveGState()

        // Offset shadow down and slightly right for late-afternoon sun feel
        context.translateBy(x: 3, y: -6)

        context.setLineWidth(thickness + 4)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(CGColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 0.25))

        context.addPath(path)
        context.strokePath()

        // Softer wider shadow
        context.setLineWidth(thickness + 10)
        context.setStrokeColor(CGColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 0.08))
        context.addPath(path)
        context.strokePath()

        context.restoreGState()
    }

    /// Draws the paperclip wire with a metallic gradient fill for a chrome/silver look.
    private func drawMetallicPaperclip(
        path: CGPath,
        thickness: CGFloat,
        hueShift: CGFloat,
        in context: CGContext
    ) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Convert the stroke path to a filled shape so we can clip a gradient into it
        context.saveGState()

        context.setLineWidth(thickness)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(path)

        // Use replacePathWithStrokedPath to convert the stroke into a fillable area
        context.replacePathWithStrokedPath()

        // Save the stroked outline as a clipping region
        let strokedPath = context.path?.copy()
        guard let clippingPath = strokedPath else {
            context.restoreGState()
            return
        }

        // Get the bounding box for the gradient
        let pathBounds = clippingPath.boundingBoxOfPath

        // Clip to the stroked path
        context.addPath(clippingPath)
        context.clip()

        // Draw metallic gradient across the paperclip (perpendicular to length for sheen)
        // Silver with highlights: dark edge -> bright highlight -> mid silver -> bright -> dark edge
        let r = 0.75 + hueShift
        let g = 0.75 + hueShift * 0.5
        let b = 0.78 + hueShift * 0.3

        let metallicColors = [
            CGColor(red: r * 0.55, green: g * 0.55, blue: b * 0.58, alpha: 1.0),  // Dark edge
            CGColor(red: r * 0.75, green: g * 0.75, blue: b * 0.78, alpha: 1.0),  // Mid
            CGColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0),              // Bright highlight
            CGColor(red: r * 0.80, green: g * 0.80, blue: b * 0.82, alpha: 1.0),  // Mid-bright
            CGColor(red: r * 0.90, green: g * 0.90, blue: b * 0.92, alpha: 1.0),  // Light
            CGColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0),              // Second highlight
            CGColor(red: r * 0.60, green: g * 0.60, blue: b * 0.63, alpha: 1.0),  // Dark edge
        ] as CFArray

        let metallicLocations: [CGFloat] = [0.0, 0.15, 0.3, 0.45, 0.65, 0.8, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: metallicColors, locations: metallicLocations) {
            // Draw gradient at a slight angle for more natural metallic look
            let angle: CGFloat = 0.3
            let dy = pathBounds.width * sin(angle)
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: pathBounds.minX, y: pathBounds.midY - dy / 2),
                end: CGPoint(x: pathBounds.maxX, y: pathBounds.midY + dy / 2),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }

        context.restoreGState()

        // Add a thin bright edge highlight on top for that polished metal look
        context.saveGState()
        context.setLineWidth(max(1.0, thickness * 0.25))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25))
        context.addPath(path)
        context.strokePath()
        context.restoreGState()

        // Subtle dark outline for definition
        context.saveGState()
        context.setLineWidth(thickness + 1.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(CGColor(red: 0.3, green: 0.28, blue: 0.26, alpha: 0.15))
        context.addPath(path)
        context.strokePath()
        context.restoreGState()

        // Re-draw the metallic fill on top of the outline
        context.saveGState()
        context.setLineWidth(thickness)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(path)
        context.replacePathWithStrokedPath()

        let strokedPath2 = context.path?.copy()
        if let clippingPath2 = strokedPath2 {
            let pathBounds2 = clippingPath2.boundingBoxOfPath
            context.addPath(clippingPath2)
            context.clip()

            let metallicColors2 = [
                CGColor(red: r * 0.58, green: g * 0.58, blue: b * 0.60, alpha: 1.0),
                CGColor(red: r * 0.78, green: g * 0.78, blue: b * 0.80, alpha: 1.0),
                CGColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0),
                CGColor(red: r * 0.82, green: g * 0.82, blue: b * 0.84, alpha: 1.0),
                CGColor(red: r * 0.92, green: g * 0.92, blue: b * 0.94, alpha: 1.0),
                CGColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1.0),
                CGColor(red: r * 0.62, green: g * 0.62, blue: b * 0.64, alpha: 1.0),
            ] as CFArray

            if let gradient2 = CGGradient(colorsSpace: colorSpace, colors: metallicColors2, locations: metallicLocations) {
                let angle: CGFloat = 0.3
                let dy = pathBounds2.width * sin(angle)
                context.drawLinearGradient(
                    gradient2,
                    start: CGPoint(x: pathBounds2.minX, y: pathBounds2.midY - dy / 2),
                    end: CGPoint(x: pathBounds2.maxX, y: pathBounds2.midY + dy / 2),
                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
                )
            }
        }
        context.restoreGState()
    }

    // MARK: - Floating Shape

    private func drawFloatingShape(in context: CGContext) {
        let shape = sceneData.floatingShape
        let cx = bounds.width * shape.centerX
        let cy = bounds.height * shape.centerY
        let size = bounds.width * shape.size
        let alpha = shape.opacity

        context.saveGState()

        // Ethereal glow behind the shape
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let glowColors = [
            CGColor(red: 0.95, green: 0.90, blue: 0.75, alpha: alpha * 0.4),
            CGColor(red: 0.95, green: 0.90, blue: 0.75, alpha: 0.0),
        ] as CFArray

        if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1]) {
            context.drawRadialGradient(
                glow,
                startCenter: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endCenter: CGPoint(x: cx, y: cy),
                endRadius: size * 2.5,
                options: []
            )
        }

        context.setFillColor(CGColor(red: 0.95, green: 0.92, blue: 0.82, alpha: alpha))

        switch shape.type {
        case .circle:
            context.fillEllipse(in: CGRect(x: cx - size / 2, y: cy - size / 2, width: size, height: size))

        case .triangle:
            context.beginPath()
            context.move(to: CGPoint(x: cx, y: cy + size / 2))
            context.addLine(to: CGPoint(x: cx - size / 2, y: cy - size / 2))
            context.addLine(to: CGPoint(x: cx + size / 2, y: cy - size / 2))
            context.closePath()
            context.fillPath()

        case .diamond:
            context.beginPath()
            context.move(to: CGPoint(x: cx, y: cy + size / 2))
            context.addLine(to: CGPoint(x: cx + size / 3, y: cy))
            context.addLine(to: CGPoint(x: cx, y: cy - size / 2))
            context.addLine(to: CGPoint(x: cx - size / 3, y: cy))
            context.closePath()
            context.fillPath()

        case .crescent:
            // Draw a crescent moon shape
            let outer = CGRect(x: cx - size / 2, y: cy - size / 2, width: size, height: size)
            let innerOffset = size * 0.25
            let inner = CGRect(
                x: cx - size / 2 + innerOffset,
                y: cy - size / 2 + innerOffset * 0.3,
                width: size * 0.8,
                height: size * 0.8
            )
            context.beginPath()
            context.addEllipse(in: outer)
            context.fillPath()

            // Cut out the inner circle with the desert/sky color
            // Use even-odd rule for crescent effect
            context.saveGState()
            // Draw inner circle in a blended color matching the sky at that position
            let skyBlend = CGColor(red: 0.25, green: 0.15, blue: 0.40, alpha: alpha * 1.2)
            context.setFillColor(skyBlend)
            context.fillEllipse(in: inner)
            context.restoreGState()
        }

        context.restoreGState()
    }

    // MARK: - Atmospheric Haze

    private func drawAtmosphericHaze(in context: CGContext) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let hazeHeight = horizonY * 0.4
        let hazeBottom = horizonY - hazeHeight / 2
        let intensity = sceneData.hazeIntensity

        // A warm hazy band at the horizon
        let hazeColors = [
            CGColor(red: 0.90, green: 0.75, blue: 0.55, alpha: 0.0),
            CGColor(red: 0.90, green: 0.75, blue: 0.55, alpha: intensity * 0.4),
            CGColor(red: 0.90, green: 0.78, blue: 0.60, alpha: intensity * 0.5),
            CGColor(red: 0.90, green: 0.75, blue: 0.55, alpha: intensity * 0.3),
            CGColor(red: 0.90, green: 0.75, blue: 0.55, alpha: 0.0),
        ] as CFArray

        let locations: [CGFloat] = [0.0, 0.25, 0.5, 0.75, 1.0]

        guard let haze = CGGradient(colorsSpace: colorSpace, colors: hazeColors, locations: locations) else { return }

        context.saveGState()
        context.clip(to: CGRect(x: 0, y: hazeBottom, width: bounds.width, height: hazeHeight))
        context.drawLinearGradient(
            haze,
            start: CGPoint(x: bounds.midX, y: hazeBottom),
            end: CGPoint(x: bounds.midX, y: hazeBottom + hazeHeight),
            options: []
        )
        context.restoreGState()
    }

    // MARK: - Stop Code Text (Ethereal Cloud Text)

    private func drawStopCodeText(in context: CGContext) {
        let stopCode = sceneData.stopCode

        // Primary text: faint in the upper sky
        let textY = bounds.height * 0.82
        let fontSize = min(16.0, max(9.0, bounds.height * 0.018))

        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .light)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(0.30),
            .paragraphStyle: paragraphStyle,
        ]

        let line1 = "Stop code: \(stopCode)"
        let line2 = String(format: "0x%08X 0x%08X", UInt32.random(in: 0...UInt32.max), UInt32.random(in: 0...UInt32.max))

        let textX = bounds.width * 0.06
        let maxWidth = bounds.width * 0.5

        let str1 = NSAttributedString(string: line1, attributes: attributes)
        let str2 = NSAttributedString(string: line2, attributes: attributes)

        let rect1 = CGRect(x: textX, y: textY, width: maxWidth, height: fontSize * 2)
        let rect2 = CGRect(x: textX, y: textY - fontSize * 1.5, width: maxWidth, height: fontSize * 2)

        str1.draw(in: rect1)
        str2.draw(in: rect2)

        // Extra-faint secondary text higher up for atmosphere
        let ghostAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.85, weight: .ultraLight),
            .foregroundColor: NSColor.white.withAlphaComponent(0.12),
            .paragraphStyle: paragraphStyle,
        ]

        let ghostLine = "collecting diagnostic data..."
        let ghostStr = NSAttributedString(string: ghostLine, attributes: ghostAttrs)
        let ghostRect = CGRect(x: textX, y: textY - fontSize * 3.5, width: maxWidth, height: fontSize * 2)
        ghostStr.draw(in: ghostRect)
    }
}
