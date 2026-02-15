import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar app - no dock icon
        NSApp.setActivationPolicy(.accessory)

        // Start the scheduler
        ScheduleManager.shared.onTrigger = {
            // TODO: Show blue screen overlay (will be implemented in task 3)
            print("[BSOD] Trigger fired — blue screen overlay not yet implemented")
        }
        ScheduleManager.shared.start()
    }
}
