import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = BlueScreenOverlay()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar app - no dock icon
        NSApp.setActivationPolicy(.accessory)

        // Start the scheduler
        ScheduleManager.shared.onTrigger = { [weak self] in
            self?.overlay.show()
        }
        ScheduleManager.shared.start()
    }
}
