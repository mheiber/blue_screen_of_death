import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = BlueScreenOverlay()
    private let stylePreviewController = StylePreviewController()
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
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]
            )
            button.target = self

            // Accessibility
            button.setAccessibilityLabel(L("a11y.statusItem.label"))
            button.setAccessibilityHelp(L("a11y.statusItem.hint"))
        }

        // Start the scheduler
        ScheduleManager.shared.onTrigger = { [weak self] in
            self?.overlay.show()
        }
        ScheduleManager.shared.start()

        // Start the lunch reminder scheduler
        LunchReminderScheduler.shared.onTrigger = { [weak self] in
            self?.overlay.show()
        }
        LunchReminderScheduler.shared.start()
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
        // Re-randomize language each time menu opens in random mode
        if LocalizationManager.shared.currentLanguage == "random" {
            LocalizationManager.shared.loadRandomLanguage()
        }

        let menu = NSMenu()
        let prefs = Preferences.shared
        let scheduler = ScheduleManager.shared

        // Trigger Now (also available via right-click menu)
        menu.addItem(NSMenuItem(title: L("menu.triggerNow"), action: #selector(triggerNow), keyEquivalent: ""))

        menu.addItem(.separator())

        // Enabled toggle
        let enabledItem = NSMenuItem(title: L("menu.enabled"), action: #selector(toggleEnabled), keyEquivalent: "")
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
        let randomItem = NSMenuItem(title: L("style.random"), action: #selector(selectStyle(_:)), keyEquivalent: "")
        randomItem.representedObject = "random"
        randomItem.state = (prefs.selectedStyleRaw == "random") ? .on : .off
        styleMenu.addItem(randomItem)
        styleMenu.delegate = self

        let styleMenuItem = NSMenuItem(title: L("menu.styleFormat", styleDisplayName(prefs)), action: nil, keyEquivalent: "")
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
            item.representedObject = interval.rawValue
            item.state = (!prefs.useCustomInterval && prefs.selectedIntervalRaw == interval.rawValue) ? .on : .off
            intervalMenu.addItem(item)
        }
        intervalMenu.addItem(.separator())
        let customIntervalItem = NSMenuItem(
            title: prefs.useCustomInterval ? L("interval.customFormat", prefs.customMinutes) : L("interval.custom"),
            action: #selector(openCustomInterval),
            keyEquivalent: ""
        )
        customIntervalItem.state = prefs.useCustomInterval ? .on : .off
        intervalMenu.addItem(customIntervalItem)

        let intervalMenuItem = NSMenuItem(
            title: L("menu.intervalFormat", prefs.intervalDisplayName),
            action: nil,
            keyEquivalent: ""
        )
        intervalMenuItem.submenu = intervalMenu
        menu.addItem(intervalMenuItem)

        // Custom Schedule
        menu.addItem(NSMenuItem(title: L("menu.customSchedule"), action: #selector(openCustomSchedule), keyEquivalent: ""))

        // Screen Share Suppression
        let screenShareItem = NSMenuItem(
            title: L("menu.suppressScreenShare"),
            action: #selector(toggleScreenShareSuppression),
            keyEquivalent: ""
        )
        screenShareItem.state = prefs.suppressDuringScreenShare ? .on : .off
        menu.addItem(screenShareItem)

        // Lunch Reminder (independent of interval)
        let lunchTitle: String
        if prefs.lunchReminderEnabled {
            let timeStr = String(format: "%d:%02d", prefs.lunchReminderHour, prefs.lunchReminderMinute)
            lunchTitle = L("menu.lunchReminderFormat", timeStr)
        } else {
            lunchTitle = L("menu.lunchReminder")
        }
        let lunchItem = NSMenuItem(
            title: lunchTitle,
            action: #selector(openLunchReminder),
            keyEquivalent: ""
        )
        lunchItem.state = prefs.lunchReminderEnabled ? .on : .off
        menu.addItem(lunchItem)

        // Next trigger info
        if let next = scheduler.nextTriggerDate, prefs.isEnabled {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let relative = formatter.localizedString(for: next, relativeTo: Date())
            let infoItem = NSMenuItem(title: L("menu.nextFormat", relative), action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
        }

        menu.addItem(.separator())

        // Language submenu with globe icon
        let languageMenu = NSMenu()

        // System Default option
        let systemItem = NSMenuItem(title: L("language.system"), action: #selector(selectLanguage(_:)), keyEquivalent: "")
        systemItem.representedObject = "system"
        systemItem.state = (LocalizationManager.shared.currentLanguage == "system") ? .on : .off
        languageMenu.addItem(systemItem)

        // Random option
        let randomLangItem = NSMenuItem(title: L("language.random"), action: #selector(selectLanguage(_:)), keyEquivalent: "")
        randomLangItem.representedObject = "random"
        randomLangItem.state = (LocalizationManager.shared.currentLanguage == "random") ? .on : .off
        languageMenu.addItem(randomLangItem)

        languageMenu.addItem(.separator())

        // All supported languages
        for lang in LocalizationManager.supportedLanguages {
            let title = lang.nativeName
            let item = NSMenuItem(title: title, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.representedObject = lang.code
            item.state = (LocalizationManager.shared.currentLanguage == lang.code) ? .on : .off
            languageMenu.addItem(item)
        }

        let languageMenuItem = NSMenuItem(
            title: "\(L("menu.language")): \(LocalizationManager.shared.currentLanguageDisplayName)",
            action: nil,
            keyEquivalent: ""
        )
        languageMenuItem.submenu = languageMenu
        if let globeImage = NSImage(systemSymbolName: "globe", accessibilityDescription: L("menu.language")) {
            globeImage.isTemplate = true
            languageMenuItem.image = globeImage
        }
        menu.addItem(languageMenuItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: L("menu.about"), action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L("menu.quit"), action: #selector(quit), keyEquivalent: "q"))

        // Show the menu
        menu.delegate = self
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear menu so left-click works again next time
        statusItem.menu = nil
    }

    private func styleDisplayName(_ prefs: Preferences) -> String {
        if let style = prefs.selectedStyle {
            return style.displayName
        }
        return L("style.random")
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
        guard let raw = sender.representedObject as? String else { return }
        Preferences.shared.useCustomInterval = false
        Preferences.shared.selectedIntervalRaw = raw
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        LocalizationManager.shared.currentLanguage = code
    }

    @objc private func openCustomInterval() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L("customInterval.title")
        window.contentView = NSHostingView(rootView: CustomIntervalView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleScreenShareSuppression() {
        Preferences.shared.suppressDuringScreenShare.toggle()
    }

    @objc private func openCustomSchedule() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L("schedule.title")
        window.contentView = NSHostingView(rootView: CustomScheduleView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openLunchReminder() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L("lunch.title")
        window.contentView = NSHostingView(rootView: LunchReminderView())
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
        window.title = L("menu.about")
        window.contentView = NSHostingView(rootView: AboutView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSMenuDelegate (style preview on hover)

extension AppDelegate: NSMenuDelegate {
    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        guard let item = item,
              let rawValue = item.representedObject as? String else {
            // Mouse left all items or moved to a separator/non-style item
            stylePreviewController.hidePreview()
            return
        }

        if let style = ScreenStyle(rawValue: rawValue) {
            stylePreviewController.showPreview(for: style)
        } else if rawValue == "random" {
            stylePreviewController.showPreview(for: nil)
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        stylePreviewController.hidePreview()
    }
}
