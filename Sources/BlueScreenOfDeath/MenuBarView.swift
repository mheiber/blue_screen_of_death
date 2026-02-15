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

        // Screen Style submenu
        Menu("Style: \(styleDisplayName)") {
            ForEach(ScreenStyle.allCases) { style in
                Button {
                    preferences.selectedStyleRaw = style.rawValue
                } label: {
                    if preferences.selectedStyleRaw == style.rawValue {
                        Text("✓ \(style.displayName)")
                    } else {
                        Text("  \(style.displayName)")
                    }
                }
            }

            Divider()

            Button {
                preferences.selectedStyleRaw = "random"
            } label: {
                if preferences.selectedStyleRaw == "random" {
                    Text("✓ Random")
                } else {
                    Text("  Random")
                }
            }
        }

        // Interval submenu
        Menu("Interval: \(preferences.intervalDisplayName)") {
            ForEach(TriggerInterval.allCases) { interval in
                Button {
                    preferences.useCustomInterval = false
                    preferences.intervalSeconds = interval.rawValue
                } label: {
                    if !preferences.useCustomInterval && interval.rawValue == preferences.intervalSeconds {
                        Text("✓ \(interval.displayName)")
                    } else {
                        Text("  \(interval.displayName)")
                    }
                }
            }

            Divider()

            Button {
                openCustomIntervalWindow()
            } label: {
                if preferences.useCustomInterval {
                    Text("✓ Custom (\(preferences.customMinutes) min)...")
                } else {
                    Text("  Custom...")
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

    private var styleDisplayName: String {
        if let style = preferences.selectedStyle {
            return style.displayName
        }
        return "Random"
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

    private func openCustomIntervalWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Custom Interval"
        window.contentView = NSHostingView(rootView: CustomIntervalView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct CustomIntervalView: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var minutesText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Custom Interval")
                .font(.headline)

            HStack {
                Text("Minutes:")
                TextField("20", text: $minutesText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onAppear {
                        minutesText = "\(preferences.customMinutes)"
                    }
            }

            Text("Range: 1–240 minutes")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Apply") {
                if let mins = Int(minutesText), mins >= 1, mins <= 240 {
                    preferences.customMinutes = mins
                    preferences.useCustomInterval = true
                }
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .frame(width: 280)
    }
}
