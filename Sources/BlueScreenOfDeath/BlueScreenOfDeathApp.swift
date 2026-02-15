import SwiftUI

@main
struct BlueScreenOfDeathApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — everything is in the menu bar status item
        Settings {
            EmptyView()
        }
    }
}
