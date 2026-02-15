import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = BlueScreenOverlay()
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "0x"
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        // Start the scheduler
        ScheduleManager.shared.onTrigger = { [weak self] in
            self?.overlay.show()
        }
        ScheduleManager.shared.start()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showConfigMenu()
        } else {
            // Left click triggers immediately
            overlay.show()
        }
    }

    // MARK: - Config Menu (right-click)

    private func showConfigMenu() {
        let menu = NSMenu()
        let prefs = Preferences.shared
        let scheduler = ScheduleManager.shared

        // Trigger Now (also available via right-click menu)
        menu.addItem(NSMenuItem(title: "Trigger Now", action: #selector(triggerNow), keyEquivalent: ""))

        menu.addItem(.separator())

        // Enabled toggle
        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.state = prefs.isEnabled ? .on : .off
        menu.addItem(enabledItem)

        // Screen Style submenu
        let styleMenu = NSMenu()
        for style in ScreenStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(selectStyle(_:)), keyEquivalent: "")
            item.representedObject = style.rawValue
            item.state = (prefs.selectedStyleRaw == style.rawValue) ? .on : .off
            styleMenu.addItem(item)
        }
        styleMenu.addItem(.separator())
        let randomItem = NSMenuItem(title: "Random", action: #selector(selectStyle(_:)), keyEquivalent: "")
        randomItem.representedObject = "random"
        randomItem.state = (prefs.selectedStyleRaw == "random") ? .on : .off
        styleMenu.addItem(randomItem)

        let styleMenuItem = NSMenuItem(title: "Style: \(styleDisplayName(prefs))", action: nil, keyEquivalent: "")
        styleMenuItem.submenu = styleMenu
        menu.addItem(styleMenuItem)

        // Interval submenu
        let intervalMenu = NSMenu()
        for interval in TriggerInterval.allCases {
            let item = NSMenuItem(
                title: interval.displayName,
                action: #selector(selectInterval(_:)),
                keyEquivalent: ""
            )
            item.tag = interval.rawValue
            item.state = (!prefs.useCustomInterval && prefs.intervalSeconds == interval.rawValue) ? .on : .off
            intervalMenu.addItem(item)
        }
        intervalMenu.addItem(.separator())
        let customIntervalItem = NSMenuItem(
            title: prefs.useCustomInterval ? "Custom (\(prefs.customMinutes) min)..." : "Custom...",
            action: #selector(openCustomInterval),
            keyEquivalent: ""
        )
        customIntervalItem.state = prefs.useCustomInterval ? .on : .off
        intervalMenu.addItem(customIntervalItem)

        let intervalMenuItem = NSMenuItem(
            title: "Interval: \(prefs.intervalDisplayName)",
            action: nil,
            keyEquivalent: ""
        )
        intervalMenuItem.submenu = intervalMenu
        menu.addItem(intervalMenuItem)

        // Custom Schedule
        menu.addItem(NSMenuItem(title: "Custom Schedule...", action: #selector(openCustomSchedule), keyEquivalent: ""))

        // Next trigger info
        if let next = scheduler.nextTriggerDate, prefs.isEnabled {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let relative = formatter.localizedString(for: next, relativeTo: Date())
            let infoItem = NSMenuItem(title: "Next: \(relative)", action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
        }

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Lock Screen", action: #selector(lockScreen), keyEquivalent: ""))

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "About Blue Screen of Death", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        // Show the menu
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear menu so left-click works again next time
        statusItem.menu = nil
    }

    private func styleDisplayName(_ prefs: Preferences) -> String {
        if let style = prefs.selectedStyle {
            return style.displayName
        }
        return "Random"
    }

    // MARK: - Actions

    @objc private func triggerNow() {
        overlay.show()
    }

    @objc private func toggleEnabled() {
        Preferences.shared.isEnabled.toggle()
    }

    @objc private func selectStyle(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String else { return }
        Preferences.shared.selectedStyleRaw = raw
    }

    @objc private func selectInterval(_ sender: NSMenuItem) {
        Preferences.shared.useCustomInterval = false
        Preferences.shared.intervalSeconds = sender.tag
    }

    @objc private func openCustomInterval() {
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

    @objc private func openCustomSchedule() {
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

    @objc private func openAbout() {
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

    @objc private func lockScreen() {
        // Show the blue screen overlay, then lock the real screen behind it
        overlay.show()
        // SACLockScreenImmediate locks the display (same as Ctrl+Cmd+Q)
        let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        if let handle = libHandle {
            typealias SACLockFunc = @convention(c) () -> Void
            if let sym = dlsym(handle, "SACLockScreenImmediate") {
                let lockFunc = unsafeBitCast(sym, to: SACLockFunc.self)
                lockFunc()
            }
            dlclose(handle)
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
