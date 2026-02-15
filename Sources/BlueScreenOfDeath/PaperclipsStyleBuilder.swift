import AppKit

// MARK: - Paperclips (Dali Surrealist) Style Builder

/// Builds a Salvador Dali-inspired surrealist BSOD scene featuring melting paperclips
/// draped across a warm desert landscape. Think "The Persistence of Memory" but with
/// paperclips instead of clocks. Every render is procedurally unique.
struct PaperclipsStyleBuilder {

    // MARK: - Public Entry Point

    /// Build the Dali-inspired surrealist paperclips view for the given frame.
    static func buildView(frame: NSRect) -> NSView {
        let sceneData = SceneData(frame: frame)
        let view = DaliPaperclipsView(frame: frame, sceneData: sceneData)
        return view
    }
}

// MARK: - Scene Data (Randomized Once Per Render)

private struct PaperclipData {
    let centerX: CGFloat      // Normalized 0-1
    let centerY: CGFloat      // Normalized 0-1
    let scale: CGFloat         // Size multiplier relative to screen
    let rotation: CGFloat      // Radians
    let meltFactor: CGFloat    // 0.5 = gently melted, 2.0 = extremely melted
    let drapeFactor: CGFloat   // How much it drapes over an edge
    let drapeEdgeY: CGFloat    // Normalized Y of the invisible edge to drape over
    let wireThickness: CGFloat // Relative to screen
    let hueShift: CGFloat      // Slight color variation for metallic sheen
    let waviness: CGFloat      // Sinusoidal wave amplitude
    let waveFrequency: CGFloat // Frequency of the melt waviness
    let hasDrapeShelf: Bool    // Whether it sits on a visible shelf/edge
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
    let shadowAngle: CGFloat
    let shadowCount: Int
    let stopCode: String
    let hazeIntensity: CGFloat

    init(frame: NSRect) {
        let clipCount = Int.random(in: 4...6)
        var clips: [PaperclipData] = []

        // Create a mix: some large foreground clips draped over edges, some mid-size
        for i in 0..<clipCount {
            let isLarge = i < 2
            let isMedium = i >= 2 && i < 4

            let baseScale: CGFloat
            let yRange: ClosedRange<CGFloat>
            let meltRange: ClosedRange<CGFloat>

            if isLarge {
                // Big dramatic foreground paperclips draped over things
                baseScale = CGFloat.random(in: 0.22...0.35)
                yRange = 0.20...0.50
                meltRange = 1.2...2.5
            } else if isMedium {
                // Medium clips on the horizon area
                baseScale = CGFloat.random(in: 0.12...0.20)
                yRange = 0.30...0.55
                meltRange = 0.8...1.8
            } else {
                // Smaller background clips
                baseScale = CGFloat.random(in: 0.06...0.12)
                yRange = 0.40...0.65
                meltRange = 0.5...1.2
            }

            let hasDrape = isLarge || (isMedium && Bool.random())

            clips.append(PaperclipData(
                centerX: CGFloat.random(in: 0.10...0.90),
                centerY: CGFloat.random(in: yRange),
                scale: baseScale,
                rotation: CGFloat.random(in: -0.6...0.6),
                meltFactor: CGFloat.random(in: meltRange),
                drapeFactor: hasDrape ? CGFloat.random(in: 0.5...1.5) : 0,
                drapeEdgeY: CGFloat.random(in: 0.28...0.45),
                wireThickness: CGFloat.random(in: 0.004...0.007),
                hueShift: CGFloat.random(in: -0.05...0.05),
                waviness: CGFloat.random(in: 0.02...0.06),
                waveFrequency: CGFloat.random(in: 3.0...8.0),
                hasDrapeShelf: hasDrape && Bool.random()
            ))
        }

        // Sort by scale so smaller (background) clips are drawn first
        self.paperclips = clips.sorted { $0.scale < $1.scale }

        let shapeTypes: [FloatingShapeData.ShapeType] = [.circle, .triangle, .diamond, .crescent]
        self.floatingShape = FloatingShapeData(
            type: shapeTypes.randomElement()!,
            centerX: CGFloat.random(in: 0.15...0.85),
            centerY: CGFloat.random(in: 0.72...0.92),
            size: CGFloat.random(in: 0.03...0.07),
            opacity: CGFloat.random(in: 0.3...0.6)
        )

        self.showCheckerboard = Bool.random()
        self.shadowAngle = CGFloat.random(in: -0.4...0.4)
        self.shadowCount = Int.random(in: 4...8)
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
        drawDrapeShelves(in: context)
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

        let colors = [
            CGColor(red: 0.106, green: 0.078, blue: 0.392, alpha: 1.0),
            CGColor(red: 0.180, green: 0.110, blue: 0.450, alpha: 1.0),
            CGColor(red: 0.350, green: 0.150, blue: 0.420, alpha: 1.0),
            CGColor(red: 0.600, green: 0.250, blue: 0.300, alpha: 1.0),
            CGColor(red: 0.850, green: 0.450, blue: 0.180, alpha: 1.0),
            CGColor(red: 0.961, green: 0.651, blue: 0.137, alpha: 1.0),
            CGColor(red: 0.980, green: 0.780, blue: 0.350, alpha: 1.0),
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

        // Sun glow near horizon
        let colorSpace2 = CGColorSpaceCreateDeviceRGB()
        let sunCenter = CGPoint(x: bounds.width * 0.65, y: horizonY + bounds.height * 0.02)
        let glowColors = [
            CGColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 0.35),
            CGColor(red: 1.0, green: 0.70, blue: 0.3, alpha: 0.15),
            CGColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 0.0),
        ] as CFArray
        if let glow = CGGradient(colorsSpace: colorSpace2, colors: glowColors, locations: [0, 0.4, 1]) {
            context.drawRadialGradient(glow, startCenter: sunCenter, startRadius: 0,
                                       endCenter: sunCenter, endRadius: bounds.width * 0.35, options: [])
        }
    }

    // MARK: - Desert

    private func drawDesert(in context: CGContext) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            CGColor(red: 0.900, green: 0.750, blue: 0.580, alpha: 1.0),
            CGColor(red: 0.831, green: 0.647, blue: 0.455, alpha: 1.0),
            CGColor(red: 0.700, green: 0.530, blue: 0.360, alpha: 1.0),
            CGColor(red: 0.545, green: 0.424, blue: 0.259, alpha: 1.0),
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
            let perspT0 = pow(t0, 2.5)
            let perspT1 = pow(t1, 2.5)
            let y0 = vanishY - perspT0 * vanishY
            let y1 = vanishY - perspT1 * vanishY
            let halfWidth0 = bounds.width * 0.02 + (1.0 - t0) * bounds.width * 0.8
            let halfWidth1 = bounds.width * 0.02 + (1.0 - t1) * bounds.width * 0.8

            for col in 0..<tileCountX {
                let cx0 = CGFloat(col) / CGFloat(tileCountX)
                let cx1 = CGFloat(col + 1) / CGFloat(tileCountX)
                let isDark = (row + col) % 2 == 0
                let alpha: CGFloat = isDark ? 0.06 : 0.03
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
            let startX = bounds.width * (0.05 + t * 0.9)
            let startY = horizonY * CGFloat.random(in: 0.05...0.35)
            let length = bounds.width * CGFloat.random(in: 0.3...0.7)
            let endX = startX + length * sin(angle)
            let endY = startY + length * cos(angle) * 0.15
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

    // MARK: - Drape Shelves (invisible edges that clips drape over)

    private func drawDrapeShelves(in context: CGContext) {
        for clip in sceneData.paperclips where clip.hasDrapeShelf {
            let shelfY = bounds.height * clip.drapeEdgeY
            let shelfX = bounds.width * clip.centerX - bounds.width * clip.scale * 0.3
            let shelfW = bounds.width * clip.scale * 0.6

            // Draw a subtle shelf/ledge — thin dark line with slight 3D effect
            context.saveGState()
            // Top highlight
            context.setStrokeColor(CGColor(red: 0.75, green: 0.65, blue: 0.50, alpha: 0.3))
            context.setLineWidth(2)
            context.beginPath()
            context.move(to: CGPoint(x: shelfX, y: shelfY + 1))
            context.addLine(to: CGPoint(x: shelfX + shelfW, y: shelfY + 1))
            context.strokePath()
            // Dark edge
            context.setStrokeColor(CGColor(red: 0.3, green: 0.22, blue: 0.15, alpha: 0.35))
            context.setLineWidth(3)
            context.beginPath()
            context.move(to: CGPoint(x: shelfX, y: shelfY))
            context.addLine(to: CGPoint(x: shelfX + shelfW, y: shelfY))
            context.strokePath()
            // Bottom shadow
            context.setStrokeColor(CGColor(red: 0.2, green: 0.15, blue: 0.10, alpha: 0.15))
            context.setLineWidth(4)
            context.beginPath()
            context.move(to: CGPoint(x: shelfX, y: shelfY - 3))
            context.addLine(to: CGPoint(x: shelfX + shelfW, y: shelfY - 3))
            context.strokePath()
            context.restoreGState()
        }
    }

    // MARK: - Paperclips (THE STAR)

    private func drawPaperclips(in context: CGContext) {
        for clip in sceneData.paperclips {
            drawSinglePaperclip(clip, in: context)
        }
    }

    private func drawSinglePaperclip(_ clip: PaperclipData, in context: CGContext) {
        // Scale relative to screen size — paperclips should be BIG
        let clipWidth = bounds.width * clip.scale * 0.4
        let clipHeight = bounds.height * clip.scale * 1.2
        let wireThickness = bounds.width * clip.wireThickness

        let cx = bounds.width * clip.centerX
        let cy = bounds.height * clip.centerY

        let path = generateMeltedPaperclipPath(
            centerX: cx, centerY: cy,
            width: clipWidth, height: clipHeight,
            rotation: clip.rotation,
            meltFactor: clip.meltFactor,
            drapeFactor: clip.drapeFactor,
            drapeEdgeY: bounds.height * clip.drapeEdgeY,
            waviness: clip.waviness,
            waveFrequency: clip.waveFrequency
        )

        drawPaperclipShadow(path: path, thickness: wireThickness, in: context)
        drawMetallicPaperclip(path: path, thickness: wireThickness, hueShift: clip.hueShift, in: context)
    }

    /// Generates the bezier path for a dramatically melting paperclip.
    ///
    /// A paperclip is two parallel rails connected by U-turns. The "melt" transform
    /// progressively pulls lower points downward with gravity-like acceleration,
    /// adds sinusoidal waviness, and creates the distinctive Dali-esque droop.
    private func generateMeltedPaperclipPath(
        centerX: CGFloat, centerY: CGFloat,
        width: CGFloat, height: CGFloat,
        rotation: CGFloat,
        meltFactor: CGFloat,
        drapeFactor: CGFloat,
        drapeEdgeY: CGFloat,
        waviness: CGFloat,
        waveFrequency: CGFloat
    ) -> CGMutablePath {

        let path = CGMutablePath()

        let halfW = width / 2.0
        let innerHalfW = halfW * 0.55
        let topY = height * 0.5
        let botY = -height * 0.5
        let innerTopY = topY - height * 0.18

        var rawPoints: [(x: CGFloat, y: CGFloat)] = []

        // Outer left side going up
        let steps = 16
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            rawPoints.append((x: -halfW, y: botY + t * (topY - botY)))
        }

        // Top outer curve
        let curveSteps = 12
        for i in 1...curveSteps {
            let angle = CGFloat.pi - CGFloat.pi * CGFloat(i) / CGFloat(curveSteps)
            rawPoints.append((x: halfW * cos(angle), y: topY + halfW * sin(angle) * 0.35))
        }

        // Outer right side going down
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            rawPoints.append((x: halfW, y: topY - t * (topY - botY)))
        }

        // Bottom outer curve
        let botSteps = 10
        let botRadius = halfW * 0.7
        for i in 1..<botSteps {
            let angle = -CGFloat.pi / 2 + CGFloat.pi * CGFloat(i) / CGFloat(botSteps)
            rawPoints.append((x: botRadius * cos(angle), y: botY + botRadius * sin(angle) * 0.4 - botRadius * 0.3))
        }

        // Inner right side going up
        let innerSteps = 14
        for i in 0...innerSteps {
            let t = CGFloat(i) / CGFloat(innerSteps)
            rawPoints.append((x: innerHalfW, y: botY + t * (innerTopY - botY)))
        }

        // Top inner curve
        for i in 1...curveSteps {
            let angle = CGFloat.pi * CGFloat(i) / CGFloat(curveSteps)
            rawPoints.append((x: innerHalfW * cos(angle), y: innerTopY + innerHalfW * sin(angle) * 0.28))
        }

        // Inner left side going down
        for i in 0...innerSteps {
            let t = CGFloat(i) / CGFloat(innerSteps)
            rawPoints.append((x: -innerHalfW, y: innerTopY - t * (innerTopY - botY) * 0.7))
        }

        // Apply transforms: rotation, dramatic melt, drape
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        // Gravity-like acceleration: melt increases quadratically from top to bottom
        let meltGravity = height * meltFactor * 0.8

        var transformed: [CGPoint] = []
        for pt in rawPoints {
            var rx = pt.x * cosR - pt.y * sinR
            var ry = pt.x * sinR + pt.y * cosR

            // Normalized position: 0 at bottom, 1 at top (in pre-rotation space)
            let normalizedY = (pt.y - botY) / (topY - botY)

            // DRAMATIC MELT: quadratic falloff — bottom droops much more than middle
            let meltT = 1.0 - normalizedY  // 0 at top, 1 at bottom
            let meltAmount = meltGravity * meltT * meltT  // Quadratic!
            ry -= meltAmount

            // Stretching: points that droop also get pulled slightly outward
            let stretchAmount = meltAmount * 0.15
            rx += rx > 0 ? stretchAmount : -stretchAmount

            // Sinusoidal waviness — organic undulation in the drooping parts
            let wavePhase = CGFloat(pt.x) / halfW * waveFrequency + normalizedY * 3.0
            let waveAmp = height * waviness * meltT * meltT
            ry += sin(wavePhase) * waveAmp
            rx += cos(wavePhase * 0.7) * waveAmp * 0.4

            // Drape over edge: parts below the drape edge get extra gravity pull
            if drapeFactor > 0 {
                let worldY = centerY + ry
                if worldY < drapeEdgeY {
                    let below = (drapeEdgeY - worldY) / height
                    let drapeGravity = below * below * drapeFactor * height * 0.8
                    ry -= drapeGravity
                    // Spread outward when draping (like cloth over a branch)
                    rx *= 1.0 + below * drapeFactor * 0.3
                }
            }

            transformed.append(CGPoint(x: centerX + rx, y: centerY + ry))
        }

        // Build smooth curves through the transformed points
        guard transformed.count >= 3 else { return path }

        path.move(to: transformed[0])
        for i in 0..<transformed.count - 2 {
            let p0 = i > 0 ? transformed[i - 1] : transformed[i]
            let p1 = transformed[i]
            let p2 = transformed[i + 1]
            let p3 = (i + 2 < transformed.count) ? transformed[i + 2] : transformed[i + 1]

            // Catmull-Rom to cubic bezier
            let cp1x = p1.x + (p2.x - p0.x) / 6.0
            let cp1y = p1.y + (p2.y - p0.y) / 6.0
            let cp2x = p2.x - (p3.x - p1.x) / 6.0
            let cp2y = p2.y - (p3.y - p1.y) / 6.0

            path.addCurve(to: p2, control1: CGPoint(x: cp1x, y: cp1y), control2: CGPoint(x: cp2x, y: cp2y))
        }

        return path
    }

    /// Draws a soft shadow beneath the paperclip path.
    private func drawPaperclipShadow(path: CGPath, thickness: CGFloat, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: 4, y: -8)

        // Close shadow
        context.setLineWidth(thickness + 6)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(CGColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 0.30))
        context.addPath(path)
        context.strokePath()

        // Soft wide shadow
        context.setLineWidth(thickness + 16)
        context.setStrokeColor(CGColor(red: 0.1, green: 0.07, blue: 0.04, alpha: 0.10))
        context.addPath(path)
        context.strokePath()

        context.restoreGState()
    }

    /// Draws the paperclip wire with a metallic gradient fill for chrome/silver look.
    private func drawMetallicPaperclip(
        path: CGPath, thickness: CGFloat, hueShift: CGFloat, in context: CGContext
    ) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Dark outline first (slightly wider)
        context.saveGState()
        context.setLineWidth(thickness + 2)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(CGColor(red: 0.28, green: 0.26, blue: 0.24, alpha: 0.5))
        context.addPath(path)
        context.strokePath()
        context.restoreGState()

        // Convert stroke to filled shape for gradient clipping
        context.saveGState()
        context.setLineWidth(thickness)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(path)
        context.replacePathWithStrokedPath()

        guard let strokedPath = context.path?.copy() else {
            context.restoreGState()
            return
        }

        let pathBounds = strokedPath.boundingBoxOfPath
        context.addPath(strokedPath)
        context.clip()

        // Metallic gradient: multi-stop for convincing chrome
        let r = 0.75 + hueShift
        let g = 0.75 + hueShift * 0.5
        let b = 0.78 + hueShift * 0.3

        let metallicColors = [
            CGColor(red: r * 0.45, green: g * 0.45, blue: b * 0.48, alpha: 1.0),
            CGColor(red: r * 0.70, green: g * 0.70, blue: b * 0.73, alpha: 1.0),
            CGColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0),  // Bright highlight
            CGColor(red: r * 0.78, green: g * 0.78, blue: b * 0.80, alpha: 1.0),
            CGColor(red: r * 0.88, green: g * 0.88, blue: b * 0.90, alpha: 1.0),
            CGColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1.0),  // Second highlight
            CGColor(red: r * 0.50, green: g * 0.50, blue: b * 0.53, alpha: 1.0),
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.15, 0.28, 0.45, 0.62, 0.78, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: metallicColors, locations: locations) {
            let angle: CGFloat = 0.35
            let dy = pathBounds.width * sin(angle)
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: pathBounds.minX, y: pathBounds.midY - dy / 2),
                end: CGPoint(x: pathBounds.maxX, y: pathBounds.midY + dy / 2),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }

        context.restoreGState()

        // Bright edge highlight on top
        context.saveGState()
        context.setLineWidth(max(1.0, thickness * 0.2))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35))
        context.addPath(path)
        context.strokePath()
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

        // Ethereal glow
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let glowColors = [
            CGColor(red: 0.95, green: 0.90, blue: 0.75, alpha: alpha * 0.4),
            CGColor(red: 0.95, green: 0.90, blue: 0.75, alpha: 0.0),
        ] as CFArray

        if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1]) {
            context.drawRadialGradient(glow, startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                                       endCenter: CGPoint(x: cx, y: cy), endRadius: size * 2.5, options: [])
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
            let outer = CGRect(x: cx - size / 2, y: cy - size / 2, width: size, height: size)
            let innerOffset = size * 0.25
            let inner = CGRect(x: cx - size / 2 + innerOffset, y: cy - size / 2 + innerOffset * 0.3,
                              width: size * 0.8, height: size * 0.8)
            context.fillEllipse(in: outer)
            context.saveGState()
            context.setFillColor(CGColor(red: 0.25, green: 0.15, blue: 0.40, alpha: alpha * 1.2))
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
        context.drawLinearGradient(haze,
                                   start: CGPoint(x: bounds.midX, y: hazeBottom),
                                   end: CGPoint(x: bounds.midX, y: hazeBottom + hazeHeight), options: [])
        context.restoreGState()
    }

    // MARK: - Stop Code Text

    private func drawStopCodeText(in context: CGContext) {
        let stopCode = sceneData.stopCode
        let textY = bounds.height * 0.82
        let fontSize = min(16.0, max(9.0, bounds.height * 0.018))

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .light),
            .foregroundColor: NSColor.white.withAlphaComponent(0.30),
        ]
        let textX = bounds.width * 0.06
        let maxWidth = bounds.width * 0.5

        let line1 = NSAttributedString(string: "Stop code: \(stopCode)", attributes: attrs)
        let line2 = NSAttributedString(
            string: String(format: "0x%08X 0x%08X", UInt32.random(in: 0...UInt32.max), UInt32.random(in: 0...UInt32.max)),
            attributes: attrs
        )

        line1.draw(in: CGRect(x: textX, y: textY, width: maxWidth, height: fontSize * 2))
        line2.draw(in: CGRect(x: textX, y: textY - fontSize * 1.5, width: maxWidth, height: fontSize * 2))

        let ghostAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.85, weight: .ultraLight),
            .foregroundColor: NSColor.white.withAlphaComponent(0.12),
        ]
        let ghostStr = NSAttributedString(string: "collecting diagnostic data...", attributes: ghostAttrs)
        ghostStr.draw(in: CGRect(x: textX, y: textY - fontSize * 3.5, width: maxWidth, height: fontSize * 2))
    }
}
