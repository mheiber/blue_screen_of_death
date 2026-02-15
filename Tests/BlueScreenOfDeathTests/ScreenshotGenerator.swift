import XCTest
import AppKit
@testable import BlueScreenOfDeath

/// Generates PNG screenshots of BSOD styles for the README.
/// Run with: swift test --disable-sandbox --filter ScreenshotGenerator
final class ScreenshotGenerator: XCTestCase {

    private let outputDir = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]
        ?? "/tmp/winsim-screenshots")
    private let frame = NSRect(x: 0, y: 0, width: 1920, height: 1080)

    override func setUp() {
        super.setUp()
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    func testGenerateModernEnglish() throws {
        LocalizationManager.shared.currentLanguage = "en"
        let view = BlueScreenStyleBuilder.buildView(for: .modern, frame: frame)
        let data = try renderView(view)
        let url = outputDir.appendingPathComponent("modern-english.png")
        try data.write(to: url)
        print("Screenshot saved: \(url.path)")
    }

    func testGenerateCyberJapanese() throws {
        LocalizationManager.shared.currentLanguage = "ja"
        let view = BlueScreenStyleBuilder.buildView(for: .cyberwin2070, frame: frame)
        let data = try renderView(view)
        let url = outputDir.appendingPathComponent("cyber-japanese.png")
        try data.write(to: url)
        print("Screenshot saved: \(url.path)")
    }

    private func renderView(_ view: NSView) throws -> Data {
        // Put the view in an off-screen window so layout works correctly
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = view
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()

        // Force display
        view.display()

        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            throw NSError(domain: "ScreenshotGenerator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap"])
        }
        view.cacheDisplay(in: view.bounds, to: bitmap)

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "ScreenshotGenerator", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG"])
        }
        return pngData
    }
}
