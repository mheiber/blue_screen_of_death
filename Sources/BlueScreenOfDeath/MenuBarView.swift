import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var preferences = Preferences.shared
    @ObservedObject private var scheduler = ScheduleManager.shared
    @State private var showingAbout = false
    @State private var showingSchedule = false

    var body: some View {
        Button("Trigger Now") {
            scheduler.triggerNow()
        }
        .keyboardShortcut("b", modifiers: [.command, .shift])

        Divider()

        Toggle("Enabled", isOn: $preferences.isEnabled)

        // Interval submenu
        Menu("Interval: \(preferences.selectedInterval.displayName)") {
            ForEach(TriggerInterval.allCases) { interval in
                Button {
                    preferences.intervalSeconds = interval.rawValue
                } label: {
                    if interval.rawValue == preferences.intervalSeconds {
                        Text("✓ \(interval.displayName)")
                    } else {
                        Text("  \(interval.displayName)")
                    }
                }
            }
        }

        Button("Custom Schedule...") {
            openScheduleWindow()
        }

        if let next = scheduler.nextTriggerDate, preferences.isEnabled {
            Text("Next: \(next, style: .relative)")
                .font(.caption)
        }

        Divider()

        Button("About Blue Screen of Death") {
            openAboutWindow()
        }

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func openAboutWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Blue Screen of Death"
        window.contentView = NSHostingView(rootView: AboutView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openScheduleWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Custom Schedule"
        window.contentView = NSHostingView(rootView: CustomScheduleView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
