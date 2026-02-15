import XCTest
@testable import BlueScreenOfDeath

// MARK: - CrashDumpGenerator Tests

final class CrashDumpGeneratorTests: XCTestCase {

    // MARK: - All styles produce output

    func testClassicGeneratesNonEmptyString() {
        let result = CrashDumpGenerator.generate(style: .classic)
        XCTAssertFalse(result.isEmpty, "Classic style should produce non-empty output")
    }

    func testClassicDumpGeneratesNonEmptyString() {
        let result = CrashDumpGenerator.generate(style: .classicDump)
        XCTAssertFalse(result.isEmpty, "Classic dump style should produce non-empty output")
    }

    func testMojibakeGeneratesNonEmptyString() {
        let result = CrashDumpGenerator.generate(style: .mojibake)
        XCTAssertFalse(result.isEmpty, "Mojibake style should produce non-empty output")
    }

    func testModernGeneratesNonEmptyFallbackString() {
        let result = CrashDumpGenerator.generate(style: .modern)
        XCTAssertFalse(result.isEmpty, "Modern style fallback should produce non-empty output")
    }

    // MARK: - Modern style structured data

    func testModernDataHasStopCode() {
        let data = CrashDumpGenerator.generateModernData()
        XCTAssertFalse(data.stopCode.isEmpty, "Modern data should have a stop code")
    }

    func testModernDataHasPercentageInRange() {
        for _ in 0..<20 {
            let data = CrashDumpGenerator.generateModernData()
            XCTAssertGreaterThanOrEqual(data.percentage, 0, "Percentage should be >= 0")
            XCTAssertLessThanOrEqual(data.percentage, 99, "Percentage should be <= 99")
        }
    }

    func testModernDataStopCodeFromKnownList() {
        let knownStopCodes = [
            "IRQL_NOT_LESS_OR_EQUAL",
            "PAGE_FAULT_IN_NONPAGED_AREA",
            "KERNEL_DATA_INPAGE_ERROR",
            "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED",
            "UNEXPECTED_KERNEL_MODE_TRAP",
            "CRITICAL_PROCESS_DIED",
            "SYSTEM_SERVICE_EXCEPTION",
            "KERNEL_SECURITY_CHECK_FAILURE",
            "CLOCK_WATCHDOG_TIMEOUT",
            "DRIVER_OVERRAN_STACK_BUFFER",
            "REFERENCE_BY_POINTER",
            "MEMORY_MANAGEMENT",
            "CACHE_MANAGER",
            "BAD_POOL_HEADER",
            "WHEA_UNCORRECTABLE_ERROR",
            "DPC_WATCHDOG_VIOLATION",
        ]

        for _ in 0..<20 {
            let data = CrashDumpGenerator.generateModernData()
            XCTAssertTrue(
                knownStopCodes.contains(data.stopCode),
                "Stop code '\(data.stopCode)' should be from the known list"
            )
        }
    }

    // MARK: - Classic style content

    func testClassicContainsWinsome() {
        let result = CrashDumpGenerator.generate(style: .classic)
        XCTAssertTrue(
            result.contains("Winsome"),
            "Classic style should reference Winsome"
        )
    }

    func testClassicContainsTroubleshootingText() {
        let result = CrashDumpGenerator.generate(style: .classic)
        XCTAssertTrue(
            result.contains("A problem has been detected"),
            "Classic style should contain header text"
        )
        XCTAssertTrue(
            result.contains("restart your computer"),
            "Classic style should contain troubleshooting text"
        )
    }

    func testClassicContainsStopCode() {
        let result = CrashDumpGenerator.generate(style: .classic)
        XCTAssertTrue(
            result.contains("*** STOP: 0x"),
            "Classic style should contain a STOP code line"
        )
    }

    func testClassicContainsDriverReference() {
        let result = CrashDumpGenerator.generate(style: .classic)
        XCTAssertTrue(
            result.contains(".SYS"),
            "Classic style should reference a .SYS driver"
        )
    }

    func testClassicStopCodeHasFourParameters() {
        let result = CrashDumpGenerator.generate(style: .classic)
        let lines = result.components(separatedBy: "\n")
        guard let stopLine = lines.first(where: { $0.contains("*** STOP:") }) else {
            XCTFail("No STOP line found in classic style")
            return
        }

        let paramPattern = try! NSRegularExpression(pattern: "0x[0-9A-Fa-f]+", options: [])
        let matches = paramPattern.matches(
            in: stopLine,
            range: NSRange(stopLine.startIndex..., in: stopLine)
        )
        // Should have 5 total: the stop code + 4 params
        XCTAssertEqual(
            matches.count, 5,
            "STOP line should have 1 stop code + 4 parameters (found \(matches.count))"
        )
    }

    // MARK: - Classic Dump style content

    func testClassicDumpContainsStopCode() {
        let result = CrashDumpGenerator.generate(style: .classicDump)
        XCTAssertTrue(
            result.contains("*** STOP: 0x"),
            "Classic dump style should contain a STOP code line"
        )
    }

    func testClassicDumpContainsDllTable() {
        let result = CrashDumpGenerator.generate(style: .classicDump)
        XCTAssertTrue(
            result.contains("Dll Base DateStmp"),
            "Classic dump style should contain DLL table header"
        )
    }

    func testClassicDumpContainsHexDump() {
        let result = CrashDumpGenerator.generate(style: .classicDump)
        XCTAssertTrue(
            result.contains("dword_dump"),
            "Classic dump style should contain hex dump section"
        )
    }

    func testClassicDumpContainsDriverModules() {
        let result = CrashDumpGenerator.generate(style: .classicDump)
        // Should contain at least some of the known module names
        let knownModules = ["wsoskrnl.exe", "wsl.dll", "wsapi.sys"]
        var foundAny = false
        for module in knownModules where result.contains(module) {
            foundAny = true
            break
        }
        XCTAssertTrue(foundAny, "Classic dump should contain known Winsome module names")
    }

    func testClassicDumpHasManyLines() {
        let result = CrashDumpGenerator.generate(style: .classicDump)
        let lines = result.components(separatedBy: "\n")
        XCTAssertGreaterThan(
            lines.count, 15,
            "Classic dump should have many lines (got \(lines.count))"
        )
    }

    // MARK: - Mojibake style content

    func testMojibakeHasManyLines() {
        let result = CrashDumpGenerator.generate(style: .mojibake)
        let lines = result.components(separatedBy: "\n")
        XCTAssertGreaterThanOrEqual(
            lines.count, 40,
            "Mojibake style should have at least 40 lines (got \(lines.count))"
        )
    }

    func testMojibakeContainsNoCommonEnglishWords() {
        let result = CrashDumpGenerator.generate(style: .mojibake)
        let commonWords = ["the ", "and ", "that ", "this ", "with ", "from ", "your "]
        for word in commonWords {
            XCTAssertFalse(
                result.lowercased().contains(word),
                "Mojibake should not contain common English word '\(word)'"
            )
        }
    }

    // MARK: - Randomness

    func testClassicProducesDifferentOutputs() {
        let results = (0..<10).map { _ in CrashDumpGenerator.generate(style: .classic) }
        let uniqueResults = Set(results)
        XCTAssertGreaterThan(
            uniqueResults.count, 1,
            "Multiple classic generations should produce different outputs"
        )
    }

    func testClassicDumpProducesDifferentOutputs() {
        let results = (0..<10).map { _ in CrashDumpGenerator.generate(style: .classicDump) }
        let uniqueResults = Set(results)
        XCTAssertGreaterThan(
            uniqueResults.count, 1,
            "Multiple classic dump generations should produce different outputs"
        )
    }

    func testMojibakeProducesDifferentOutputs() {
        let results = (0..<10).map { _ in CrashDumpGenerator.generate(style: .mojibake) }
        let uniqueResults = Set(results)
        XCTAssertGreaterThan(
            uniqueResults.count, 1,
            "Multiple mojibake generations should produce different outputs"
        )
    }

    func testModernDataProducesDifferentOutputs() {
        let results = (0..<20).map { _ in CrashDumpGenerator.generateModernData() }
        let uniqueStopCodes = Set(results.map { $0.stopCode })
        let uniquePercentages = Set(results.map { $0.percentage })
        // At least some variation expected in 20 generations
        XCTAssertGreaterThan(uniquePercentages.count, 1, "Percentages should vary")
        _ = uniqueStopCodes // stop codes may repeat due to small pool
    }

    // MARK: - Easter eggs

    func testClassicDumpContainsEasterEggHexCodes() {
        let knownEasterEggs = [
            "DEADBEEF", "CAFEBABE", "BAADF00D", "FEEDFACE",
            "00C0FFEE", "BEEFCAFE", "FACEFEED", "0D15EA5E",
        ]

        var foundAny = false
        for _ in 0..<50 {
            let result = CrashDumpGenerator.generate(style: .classicDump)
            for egg in knownEasterEggs where result.contains(egg) {
                foundAny = true
                break
            }
            if foundAny { break }
        }
        XCTAssertTrue(foundAny, "Easter egg hex codes should appear in classic dump style")
    }

    // MARK: - No trademarked terms (all styles)

    func testNoStyleContainsTrademarks() {
        let trademarks = [
            "Microsoft", "microsoft",
            "Windows", "windows",
            "NT Kernel", "nt kernel",
            "NTOSKRNL", "ntoskrnl",
            "ntdll", "NTDLL",
            "win32k", "Win32k",
        ]

        for style in ScreenStyle.allCases {
            for _ in 0..<10 {
                let result = CrashDumpGenerator.generate(style: style)
                for trademark in trademarks {
                    XCTAssertFalse(
                        result.contains(trademark),
                        "\(style.displayName) style contains trademark '\(trademark)'"
                    )
                }
            }
        }
    }
}

// MARK: - ScreenStyle Tests

final class ScreenStyleTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(ScreenStyle.allCases.count, 5)
    }

    func testCaseRawValues() {
        XCTAssertEqual(ScreenStyle.modern.rawValue, "modern")
        XCTAssertEqual(ScreenStyle.classic.rawValue, "classic")
        XCTAssertEqual(ScreenStyle.classicDump.rawValue, "classicDump")
        XCTAssertEqual(ScreenStyle.mojibake.rawValue, "mojibake")
        XCTAssertEqual(ScreenStyle.cyberwin2070.rawValue, "cyberwin2070")
    }

    func testDisplayNames() {
        XCTAssertEqual(ScreenStyle.modern.displayName, "Modern")
        XCTAssertEqual(ScreenStyle.classic.displayName, "Classic")
        XCTAssertEqual(ScreenStyle.classicDump.displayName, "Classic Dump")
        XCTAssertEqual(ScreenStyle.mojibake.displayName, "Mojibake")
        XCTAssertEqual(ScreenStyle.cyberwin2070.displayName, "CyberWin 2070")
    }

    func testIdentifiable() {
        for style in ScreenStyle.allCases {
            XCTAssertEqual(style.id, style.rawValue)
        }
    }

    func testInitFromRawValue() {
        XCTAssertEqual(ScreenStyle(rawValue: "modern"), .modern)
        XCTAssertEqual(ScreenStyle(rawValue: "classic"), .classic)
        XCTAssertEqual(ScreenStyle(rawValue: "classicDump"), .classicDump)
        XCTAssertEqual(ScreenStyle(rawValue: "mojibake"), .mojibake)
        XCTAssertEqual(ScreenStyle(rawValue: "cyberwin2070"), .cyberwin2070)
        XCTAssertNil(ScreenStyle(rawValue: "invalid"))
    }
}

// MARK: - TriggerInterval Tests

final class TriggerIntervalTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(TriggerInterval.allCases.count, 6)
    }

    func testRawValues() {
        XCTAssertEqual(TriggerInterval.twentyMinutes.rawValue, "twentyMinutes")
        XCTAssertEqual(TriggerInterval.oneHour.rawValue, "oneHour")
        XCTAssertEqual(TriggerInterval.twoHours.rawValue, "twoHours")
        XCTAssertEqual(TriggerInterval.threeHours.rawValue, "threeHours")
        XCTAssertEqual(TriggerInterval.randomShort.rawValue, "randomShort")
        XCTAssertEqual(TriggerInterval.randomLong.rawValue, "randomLong")
    }

    func testDisplayNames() {
        XCTAssertEqual(TriggerInterval.twentyMinutes.displayName, "Every 20 minutes")
        XCTAssertEqual(TriggerInterval.oneHour.displayName, "Every hour")
        XCTAssertEqual(TriggerInterval.twoHours.displayName, "Every 2 hours")
        XCTAssertEqual(TriggerInterval.threeHours.displayName, "Every 3 hours")
        XCTAssertTrue(TriggerInterval.randomShort.displayName.contains("1.5"))
        XCTAssertTrue(TriggerInterval.randomLong.displayName.contains("3"))
    }

    func testIdentifiable() {
        for interval in TriggerInterval.allCases {
            XCTAssertEqual(interval.id, interval.rawValue)
        }
    }

    func testInitFromRawValue() {
        XCTAssertEqual(TriggerInterval(rawValue: "twentyMinutes"), .twentyMinutes)
        XCTAssertEqual(TriggerInterval(rawValue: "oneHour"), .oneHour)
        XCTAssertEqual(TriggerInterval(rawValue: "twoHours"), .twoHours)
        XCTAssertEqual(TriggerInterval(rawValue: "threeHours"), .threeHours)
        XCTAssertEqual(TriggerInterval(rawValue: "randomShort"), .randomShort)
        XCTAssertEqual(TriggerInterval(rawValue: "randomLong"), .randomLong)
        XCTAssertNil(TriggerInterval(rawValue: "invalid"))
    }

    func testFixedIntervalsReturnCorrectSeconds() {
        XCTAssertEqual(TriggerInterval.twentyMinutes.intervalSeconds, 1200)
        XCTAssertEqual(TriggerInterval.oneHour.intervalSeconds, 3600)
        XCTAssertEqual(TriggerInterval.twoHours.intervalSeconds, 7200)
        XCTAssertEqual(TriggerInterval.threeHours.intervalSeconds, 10800)
    }

    func testRandomShortInRange() {
        for _ in 0..<20 {
            let secs = TriggerInterval.randomShort.intervalSeconds
            XCTAssertGreaterThanOrEqual(secs, 2700)  // 45 min
            XCTAssertLessThanOrEqual(secs, 8100)     // 2 hr 15 min
        }
    }

    func testRandomLongInRange() {
        for _ in 0..<20 {
            let secs = TriggerInterval.randomLong.intervalSeconds
            XCTAssertGreaterThanOrEqual(secs, 5400)  // 1.5 hr
            XCTAssertLessThanOrEqual(secs, 16200)    // 4.5 hr
        }
    }
}

// MARK: - Preferences Tests

final class PreferencesTests: XCTestCase {

    func testSharedInstanceExists() {
        let prefs = Preferences.shared
        XCTAssertNotNil(prefs)
    }

    func testSelectedIntervalReturnsValidInterval() {
        let prefs = Preferences.shared
        let original = prefs.selectedIntervalRaw

        prefs.selectedIntervalRaw = TriggerInterval.oneHour.rawValue
        XCTAssertEqual(prefs.selectedInterval, .oneHour)

        prefs.selectedIntervalRaw = TriggerInterval.twentyMinutes.rawValue
        XCTAssertEqual(prefs.selectedInterval, .twentyMinutes)

        prefs.selectedIntervalRaw = original
    }

    func testSelectedIntervalFallsBackToOneHourForInvalidValue() {
        let prefs = Preferences.shared
        let original = prefs.selectedIntervalRaw

        prefs.selectedIntervalRaw = "invalidValue"
        XCTAssertEqual(
            prefs.selectedInterval, .oneHour,
            "Invalid interval should fall back to oneHour"
        )

        prefs.selectedIntervalRaw = original
    }

    func testResolveStyleReturnsSelectedStyle() {
        let prefs = Preferences.shared
        let original = prefs.selectedStyleRaw

        prefs.selectedStyleRaw = "classic"
        XCTAssertEqual(prefs.resolveStyle(), .classic)

        prefs.selectedStyleRaw = "modern"
        XCTAssertEqual(prefs.resolveStyle(), .modern)

        prefs.selectedStyleRaw = "classicDump"
        XCTAssertEqual(prefs.resolveStyle(), .classicDump)

        prefs.selectedStyleRaw = "mojibake"
        XCTAssertEqual(prefs.resolveStyle(), .mojibake)

        prefs.selectedStyleRaw = original
    }

    func testResolveStyleReturnsRandomForRandomSetting() {
        let prefs = Preferences.shared
        let original = prefs.selectedStyleRaw

        prefs.selectedStyleRaw = "random"
        // Should return a valid style (not crash)
        let style = prefs.resolveStyle()
        XCTAssertTrue(ScreenStyle.allCases.contains(style))

        prefs.selectedStyleRaw = original
    }

    func testEffectiveIntervalSecondsUsesCustomWhenEnabled() {
        let prefs = Preferences.shared
        let origCustom = prefs.useCustomInterval
        let origMinutes = prefs.customMinutes
        let origInterval = prefs.selectedIntervalRaw

        prefs.useCustomInterval = true
        prefs.customMinutes = 45
        XCTAssertEqual(prefs.effectiveIntervalSeconds, 45 * 60)

        prefs.useCustomInterval = false
        prefs.selectedIntervalRaw = TriggerInterval.oneHour.rawValue
        XCTAssertEqual(prefs.effectiveIntervalSeconds, 3600)

        prefs.useCustomInterval = origCustom
        prefs.customMinutes = origMinutes
        prefs.selectedIntervalRaw = origInterval
    }

    func testCustomMinutesClampsToRange() {
        let prefs = Preferences.shared
        let original = prefs.customMinutes

        prefs.customMinutes = 0
        XCTAssertGreaterThanOrEqual(prefs.customMinutes, 1, "Should clamp to minimum 1")

        prefs.customMinutes = 500
        XCTAssertLessThanOrEqual(prefs.customMinutes, 240, "Should clamp to maximum 240")

        prefs.customMinutes = original
    }

    func testIsWithinScheduleReturnsTrueWhenCustomScheduleDisabled() {
        let prefs = Preferences.shared
        let original = prefs.useCustomSchedule

        prefs.useCustomSchedule = false
        XCTAssertTrue(
            prefs.isWithinSchedule(),
            "Should always return true when custom schedule is disabled"
        )

        prefs.useCustomSchedule = original
    }

    func testIsWithinScheduleChecksWeekday() {
        let prefs = Preferences.shared
        let originalSchedule = prefs.useCustomSchedule
        let originalWeekdays = prefs.enabledWeekdays
        let originalStart = prefs.startHour
        let originalEnd = prefs.endHour

        prefs.useCustomSchedule = true
        prefs.startHour = 0
        prefs.endHour = 23

        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        let notToday = (todayWeekday % 7) + 1
        prefs.enabledWeekdays = Set([notToday])

        XCTAssertFalse(
            prefs.isWithinSchedule(),
            "Should return false when today's weekday is not enabled"
        )

        prefs.enabledWeekdays = Set([todayWeekday])
        XCTAssertTrue(
            prefs.isWithinSchedule(),
            "Should return true when today's weekday is enabled and hour is in range"
        )

        prefs.useCustomSchedule = originalSchedule
        prefs.enabledWeekdays = originalWeekdays
        prefs.startHour = originalStart
        prefs.endHour = originalEnd
    }

    func testIsWithinScheduleChecksHours() {
        let prefs = Preferences.shared
        let originalSchedule = prefs.useCustomSchedule
        let originalWeekdays = prefs.enabledWeekdays
        let originalStart = prefs.startHour
        let originalEnd = prefs.endHour

        prefs.useCustomSchedule = true
        prefs.enabledWeekdays = Set(1...7)

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())

        let excludeStart = (currentHour + 2) % 24
        let excludeEnd = (currentHour + 4) % 24
        prefs.startHour = excludeStart
        prefs.endHour = excludeEnd

        XCTAssertFalse(
            prefs.isWithinSchedule(),
            "Should return false when current hour is outside the range"
        )

        prefs.startHour = 0
        prefs.endHour = 23
        XCTAssertTrue(
            prefs.isWithinSchedule(),
            "Should return true when current hour is within [0, 23)"
        )

        prefs.useCustomSchedule = originalSchedule
        prefs.enabledWeekdays = originalWeekdays
        prefs.startHour = originalStart
        prefs.endHour = originalEnd
    }
}

// MARK: - ScheduleManager Tests

final class ScheduleManagerTests: XCTestCase {

    func testSharedInstanceExists() {
        XCTAssertNotNil(ScheduleManager.shared)
    }

    func testTriggerNowCallsOnTrigger() {
        let manager = ScheduleManager.shared
        let originalHandler = manager.onTrigger

        var triggered = false
        manager.onTrigger = { triggered = true }

        manager.triggerNow()
        XCTAssertTrue(triggered, "triggerNow() should invoke the onTrigger callback")

        manager.onTrigger = originalHandler
    }

    func testTriggerNowWithNoHandlerDoesNotCrash() {
        let manager = ScheduleManager.shared
        let originalHandler = manager.onTrigger

        manager.onTrigger = nil
        manager.triggerNow()

        manager.onTrigger = originalHandler
    }

    func testStopClearsNextTriggerDate() {
        let manager = ScheduleManager.shared

        manager.start()
        manager.stop()

        XCTAssertNil(
            manager.nextTriggerDate,
            "After stop(), nextTriggerDate should be nil"
        )
    }

    func testStartSetsNextTriggerDate() {
        let manager = ScheduleManager.shared
        let prefs = Preferences.shared
        let originalEnabled = prefs.isEnabled

        prefs.isEnabled = true
        manager.start()

        XCTAssertNotNil(
            manager.nextTriggerDate,
            "After start() with isEnabled=true, nextTriggerDate should be set"
        )

        manager.stop()
        prefs.isEnabled = originalEnabled
    }

    func testRescheduleWhenDisabledClearsDate() {
        let manager = ScheduleManager.shared
        let prefs = Preferences.shared
        let originalEnabled = prefs.isEnabled

        prefs.isEnabled = true
        manager.start()
        XCTAssertNotNil(manager.nextTriggerDate)

        prefs.isEnabled = false
        manager.reschedule()
        XCTAssertNil(
            manager.nextTriggerDate,
            "Reschedule with isEnabled=false should clear nextTriggerDate"
        )

        prefs.isEnabled = originalEnabled
    }
}

// MARK: - ScreenShareDetector Tests

final class ScreenShareDetectorTests: XCTestCase {

    // MARK: - Definite indicators (always suppress)

    func testSuppressesWhenScreenSharingAppRunning() {
        XCTAssertTrue(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: ["com.apple.screensharing"],
                runningProcessNames: [],
                suppressDuringCalls: false
            ),
            "Should suppress when macOS Screen Sharing is running"
        )
    }

    func testSuppressesWhenScreenCaptureUIRunning() {
        XCTAssertTrue(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: ["com.apple.screencaptureui"],
                runningProcessNames: [],
                suppressDuringCalls: false
            ),
            "Should suppress when screen capture UI is running"
        )
    }

    // MARK: - Active sharing process names

    func testSuppressesWhenZoomCptHostRunning() {
        XCTAssertTrue(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: [],
                runningProcessNames: ["CptHost"],
                suppressDuringCalls: false
            ),
            "Should suppress when Zoom's CptHost (screen sharing) is running"
        )
    }

    // MARK: - Conferencing apps (suppressDuringCalls)

    func testSuppressesZoomWhenSuppressDuringCallsEnabled() {
        XCTAssertTrue(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: ["us.zoom.xos"],
                runningProcessNames: [],
                suppressDuringCalls: true
            ),
            "Should suppress when Zoom is running and suppressDuringCalls is true"
        )
    }

    func testDoesNotSuppressZoomWhenSuppressDuringCallsDisabled() {
        XCTAssertFalse(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: ["us.zoom.xos"],
                runningProcessNames: [],
                suppressDuringCalls: false
            ),
            "Should not suppress Zoom when suppressDuringCalls is false"
        )
    }

    func testSuppressesTeamsWhenSuppressDuringCallsEnabled() {
        XCTAssertTrue(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: ["com.microsoft.teams2"],
                runningProcessNames: [],
                suppressDuringCalls: true
            ),
            "Should suppress when Teams is running and suppressDuringCalls is true"
        )
    }

    // MARK: - No false positives

    func testDoesNotSuppressWhenNoRelevantAppsRunning() {
        XCTAssertFalse(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: ["com.apple.finder", "com.apple.Terminal"],
                runningProcessNames: ["Finder", "Terminal"],
                suppressDuringCalls: true
            ),
            "Should not suppress when only normal apps are running"
        )
    }

    func testDoesNotSuppressWhenEmpty() {
        XCTAssertFalse(
            ScreenShareDetector.shouldSuppress(
                runningBundleIDs: [],
                runningProcessNames: [],
                suppressDuringCalls: true
            ),
            "Should not suppress when no apps are running"
        )
    }

    // MARK: - Bundle ID lists

    func testDefiniteIndicatorBundleIDsAreNonEmpty() {
        XCTAssertFalse(ScreenShareDetector.definiteIndicatorBundleIDs.isEmpty)
    }

    func testConferencingBundleIDsAreNonEmpty() {
        XCTAssertFalse(ScreenShareDetector.conferencingBundleIDs.isEmpty)
    }

    func testActiveSharingProcessNamesAreNonEmpty() {
        XCTAssertFalse(ScreenShareDetector.activeSharingProcessNames.isEmpty)
    }

    // MARK: - All conferencing apps detected

    func testAllConferencingAppsDetectedWhenSuppressDuringCallsEnabled() {
        for bundleID in ScreenShareDetector.conferencingBundleIDs {
            XCTAssertTrue(
                ScreenShareDetector.shouldSuppress(
                    runningBundleIDs: [bundleID],
                    runningProcessNames: [],
                    suppressDuringCalls: true
                ),
                "Should suppress for conferencing app \(bundleID)"
            )
        }
    }

    func testNoConferencingAppsSuppressedWhenSuppressDuringCallsDisabled() {
        for bundleID in ScreenShareDetector.conferencingBundleIDs {
            XCTAssertFalse(
                ScreenShareDetector.shouldSuppress(
                    runningBundleIDs: [bundleID],
                    runningProcessNames: [],
                    suppressDuringCalls: false
                ),
                "Should not suppress for \(bundleID) when suppressDuringCalls is false"
            )
        }
    }

    // MARK: - Definite indicators override suppressDuringCalls=false

    func testDefiniteIndicatorsSuppressEvenWhenSuppressDuringCallsDisabled() {
        for bundleID in ScreenShareDetector.definiteIndicatorBundleIDs {
            XCTAssertTrue(
                ScreenShareDetector.shouldSuppress(
                    runningBundleIDs: [bundleID],
                    runningProcessNames: [],
                    suppressDuringCalls: false
                ),
                "Definite indicator \(bundleID) should suppress regardless of suppressDuringCalls"
            )
        }
    }
}
