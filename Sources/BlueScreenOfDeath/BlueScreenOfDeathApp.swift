import SwiftUI

@main
struct BlueScreenOfDeathApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            Text("0x")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
        }
        .menuBarExtraStyle(.menu)
    }
}
