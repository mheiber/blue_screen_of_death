import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar app - no dock icon needed
        // LSUIElement is set in Info.plist for bundled app
        NSApp.setActivationPolicy(.accessory)
    }
}
