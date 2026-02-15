import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var preferences = Preferences.shared
    @ObservedObject private var scheduler = ScheduleManager.shared

    var body: some View {
        // Trigger Now — show hotkey hint only if one is assigned
        if preferences.hasHotkey,
           let keyEquiv = hotkeyKeyEquivalent {
            Button("Trigger Now") {
                scheduler.triggerNow()
            }
            .keyboardShortcut(keyEquiv, modifiers: hotkeyEventModifiers)
        } else {
            Button("Trigger Now") {
                scheduler.triggerNow()
            }
        }

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

        // Hotkey assignment
        if preferences.hasHotkey {
            Button("Hotkey: \(hotkeyDisplayString)  (click to change)") {
                openHotkeyWindow()
            }
        } else {
            Button("Assign Hotkey...") {
                openHotkeyWindow()
            }
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

    // MARK: - Hotkey helpers

    private var styleDisplayName: String {
        if let style = preferences.selectedStyle {
            return style.displayName
        }
        return "Random"
    }

    private var hotkeyKeyEquivalent: KeyEquivalent? {
        guard preferences.hasHotkey else { return nil }
        let char = preferences.hotkeyCharacter
        // Special keys stored as Unicode symbols
        switch char {
        case "⌫": return .delete
        case "⏎": return .return
        case "⇥": return .tab
        case "↑": return .upArrow
        case "↓": return .downArrow
        case "←": return .leftArrow
        case "→": return .rightArrow
        case "⎋": return .escape
        default:
            guard let first = char.lowercased().first else { return nil }
            return KeyEquivalent(first)
        }
    }

    private var hotkeyEventModifiers: EventModifiers {
        let raw = preferences.hotkeyModifiersRaw
        let flags = NSEvent.ModifierFlags(rawValue: UInt(raw))
        var mods: EventModifiers = []
        if flags.contains(.command) { mods.insert(.command) }
        if flags.contains(.control) { mods.insert(.control) }
        if flags.contains(.option) { mods.insert(.option) }
        if flags.contains(.shift) { mods.insert(.shift) }
        return mods
    }

    private var hotkeyDisplayString: String {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(preferences.hotkeyModifiersRaw))
        var parts: [String] = []
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(preferences.hotkeyCharacter.uppercased())
        return parts.joined()
    }

    // MARK: - Window openers

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

    private func openHotkeyWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Assign Hotkey"
        window.contentView = NSHostingView(rootView: HotkeyRecorderView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Custom Interval View

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

// MARK: - Hotkey Recorder View

struct HotkeyRecorderView: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var statusMessage = ""
    @State private var isError = false
    @State private var capturedDisplay = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Assign Hotkey")
                .font(.headline)

            Text("Press a key combination, for example ⌃⌥⌦")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HotkeyCapture(
                onCapture: { character, modifiers in
                    handleCapture(character: character, modifiers: modifiers)
                },
                onEscape: {
                    preferences.clearHotkey()
                    capturedDisplay = ""
                    statusMessage = "Hotkey cleared"
                    isError = false
                }
            )
            .frame(width: 200, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary, lineWidth: 1)
            )
            .overlay(
                Text(capturedDisplay.isEmpty ? "Waiting for input..." : capturedDisplay)
                    .foregroundColor(capturedDisplay.isEmpty ? .secondary : .primary)
                    .font(.system(size: 18, design: .monospaced))
            )

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(isError ? .red : .green)
            }

            HStack(spacing: 12) {
                Button("Clear") {
                    preferences.clearHotkey()
                    capturedDisplay = ""
                    statusMessage = "Hotkey cleared"
                    isError = false
                }

                Button("Done") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            if preferences.hasHotkey {
                capturedDisplay = currentHotkeyDisplay()
            }
        }
    }

    private func handleCapture(character: String, modifiers: NSEvent.ModifierFlags) {
        if let error = Preferences.validateHotkey(character: character, modifiers: modifiers) {
            statusMessage = error
            isError = true
            return
        }

        let flags = modifiers.intersection([.command, .control, .option, .shift])
        preferences.setHotkey(character: character, modifiers: flags.rawValue)

        var parts: [String] = []
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(character.uppercased())
        capturedDisplay = parts.joined()

        statusMessage = "Hotkey assigned"
        isError = false
    }

    private func currentHotkeyDisplay() -> String {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(preferences.hotkeyModifiersRaw))
        var parts: [String] = []
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(preferences.hotkeyCharacter.uppercased())
        return parts.joined()
    }
}

// MARK: - NSView wrapper for capturing key events

struct HotkeyCapture: NSViewRepresentable {
    let onCapture: (String, NSEvent.ModifierFlags) -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> HotkeyCaptureView {
        let view = HotkeyCaptureView()
        view.onCapture = onCapture
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: HotkeyCaptureView, context: Context) {
        nsView.onCapture = onCapture
        nsView.onEscape = onEscape
    }
}

final class HotkeyCaptureView: NSView {
    var onCapture: ((String, NSEvent.ModifierFlags) -> Void)?
    var onEscape: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        // Escape clears the hotkey
        if event.keyCode == 53 {
            onEscape?()
            return
        }

        let character = keyCodeToCharacter(event.keyCode, event: event)
        guard !character.isEmpty else { return }

        onCapture?(character, event.modifierFlags)
    }

    private func keyCodeToCharacter(_ keyCode: UInt16, event: NSEvent) -> String {
        switch keyCode {
        case 51: return "⌫"         // Backspace/Delete
        case 117: return "⌦"        // Forward Delete
        case 36: return "⏎"         // Return
        case 48: return "⇥"         // Tab
        case 123: return "←"        // Left arrow
        case 124: return "→"        // Right arrow
        case 125: return "↓"        // Down arrow
        case 126: return "↑"        // Up arrow
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 49: return "Space"
        default:
            // Use the characters from the event (without modifiers)
            return event.charactersIgnoringModifiers?.lowercased() ?? ""
        }
    }
}
