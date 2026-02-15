import SwiftUI

struct MenuBarView: View {
    var body: some View {
        Text("Blue Screen of Death")
            .font(.headline)

        Divider()

        Button("Trigger Now") {
            // TODO: Trigger blue screen overlay
        }
        .keyboardShortcut("b", modifiers: [.command, .shift])

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
