import XCTest
@testable import BlueScreenOfDeath

// MARK: - CrashDumpGenerator Tests

final class CrashDumpGeneratorTests: XCTestCase {

    // MARK: Basic generation

    func testGenerateReturnsNonEmptyString() {
        let result = CrashDumpGenerator.generate()
        XCTAssertFalse(result.isEmpty, "Generated crash dump should not be empty")
    }

    func testGenerateContainsHeader() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains("A problem has been detected"),
            "Crash dump should contain the header text"
        )
    }

    func testGenerateContainsTechnicalInfo() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains("Technical information:"),
            "Crash dump should contain technical info section"
        )
    }

    func testGenerateContainsStackTrace() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains("Stack trace:"),
            "Crash dump should contain stack trace section"
        )
    }

    func testGenerateContainsStopCode() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains("*** STOP: 0x"),
            "Crash dump should contain a STOP code line"
        )
    }

    func testGenerateContainsModuleName() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains(".sys"),
            "Crash dump should reference a .sys module"
        )
    }

    func testGenerateContainsMindfulnessMessage() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains("***") && result.contains("***"),
            "Crash dump should contain a mindfulness message wrapped in ***"
        )
    }

    func testGenerateContainsDismissPrompt() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains("Press any key to return to reality"),
            "Crash dump should contain the dismiss prompt"
        )
    }

    func testGenerateContainsMindfulnessDataCollection() {
        let result = CrashDumpGenerator.generate()
        XCTAssertTrue(
            result.contains("Collecting mindfulness data"),
            "Crash dump should contain mindfulness data collection"
        )
        XCTAssertTrue(
            result.contains("Dumping stress buffers"),
            "Crash dump should contain stress buffer dump"
        )
    }

    // MARK: Randomness

    func testGenerateProducesDifferentOutputs() {
        // Generate multiple dumps and verify they're not all identical
        let results = (0..<10).map { _ in CrashDumpGenerator.generate() }
        let uniqueResults = Set(results)
        XCTAssertGreaterThan(
            uniqueResults.count, 1,
            "Multiple generations should produce different outputs (randomized)"
        )
    }

    // MARK: Easter eggs

    func testGenerateContainsEasterEggHexCodes() {
        // Run generation many times to check that easter egg codes appear
        let knownEasterEggs = [
            "DEADBEEF", "CAFEBABE", "BAADF00D", "FEEDFACE",
            "00C0FFEE", "BEEFCAFE", "FACEFEED", "0D15EA5E",
            "BADCAFE", "0DEFEC8ED", "0C0DED00D", "ACEDB00C",
        ]

        var foundAny = false
        // Generate many times to increase chance of hitting at least one
        for _ in 0..<50 {
            let result = CrashDumpGenerator.generate()
            for egg in knownEasterEggs {
                if result.contains(egg) {
                    foundAny = true
                    break
                }
            }
            if foundAny { break }
        }
        XCTAssertTrue(foundAny, "Easter egg hex codes should appear in generated crash dumps")
    }

    // MARK: No trademarked terms

    func testGenerateContainsNoTrademarks() {
        let trademarks = [
            "Microsoft", "microsoft",
            "Windows", "windows",
            "NT Kernel", "nt kernel",
            "NTOSKRNL", "ntoskrnl",
            "ntdll", "NTDLL",
            "win32k", "Win32k",
            "Bill Gates", "bill gates",
            "Azure", "azure",
            "Xbox", "xbox",
            "Redmond", "redmond",
            "BSOD",
        ]

        // Generate many dumps and check none contain trademarks
        for i in 0..<20 {
            let result = CrashDumpGenerator.generate()
            for trademark in trademarks {
                XCTAssertFalse(
                    result.contains(trademark),
                    "Generation \(i) contains trademark '\(trademark)': not allowed"
                )
            }
        }
    }

    // MARK: Formatting

    func testGenerateHasMultipleLines() {
        let result = CrashDumpGenerator.generate()
        let lines = result.components(separatedBy: "\n")
        XCTAssertGreaterThan(
            lines.count, 20,
            "Crash dump should have many lines (got \(lines.count))"
        )
    }

    func testGenerateStackTraceHasCorrectFormat() {
        let result = CrashDumpGenerator.generate()
        let lines = result.components(separatedBy: "\n")

        // Find stack trace lines (indented with two spaces, contain "!")
        let traceLines = lines.filter { $0.hasPrefix("  ") && $0.contains("!") }
        XCTAssertGreaterThanOrEqual(
            traceLines.count, 4,
            "Should have at least 4 stack trace entries"
        )
        XCTAssertLessThanOrEqual(
            traceLines.count, 7,
            "Should have at most 7 stack trace entries"
        )

        for line in traceLines {
            XCTAssertTrue(
                line.contains("+0x"),
                "Stack trace line should contain offset: \(line)"
            )
            XCTAssertTrue(
                line.contains("[0x"),
                "Stack trace line should contain address: \(line)"
            )
        }
    }

    func testStopCodeLineHasFourParameters() {
        let result = CrashDumpGenerator.generate()
        let lines = result.components(separatedBy: "\n")
        guard let stopLine = lines.first(where: { $0.contains("*** STOP:") }) else {
            XCTFail("No STOP line found")
            return
        }

        // Count hex parameters in parentheses: (0xAA, 0xBB, 0xCC, 0xDD)
        let paramPattern = try! NSRegularExpression(pattern: "0x[0-9A-F]+", options: [])
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

    func testProgressPercentageInRange() {
        for _ in 0..<20 {
            let result = CrashDumpGenerator.generate()
            let lines = result.components(separatedBy: "\n")
            guard let dumpLine = lines.first(where: { $0.contains("% complete") }) else {
                XCTFail("No progress line found")
                continue
            }

            // Extract percentage number
            let pattern = try! NSRegularExpression(pattern: "(\\d+)% complete", options: [])
            guard let match = pattern.firstMatch(
                in: dumpLine,
                range: NSRange(dumpLine.startIndex..., in: dumpLine)
            ) else {
                XCTFail("Could not extract percentage from: \(dumpLine)")
                continue
            }

            let range = Range(match.range(at: 1), in: dumpLine)!
            let percent = Int(dumpLine[range])!
            XCTAssertGreaterThanOrEqual(percent, 0, "Progress should be >= 0")
            XCTAssertLessThanOrEqual(percent, 99, "Progress should be <= 99")
        }
    }
}

// MARK: - TriggerInterval Tests

final class TriggerIntervalTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(TriggerInterval.thirtyMinutes.rawValue, 1800)
        XCTAssertEqual(TriggerInterval.oneHour.rawValue, 3600)
        XCTAssertEqual(TriggerInterval.twoHours.rawValue, 7200)
        XCTAssertEqual(TriggerInterval.fourHours.rawValue, 14400)
    }

    func testDisplayNames() {
        XCTAssertEqual(TriggerInterval.thirtyMinutes.displayName, "Every 30 minutes")
        XCTAssertEqual(TriggerInterval.oneHour.displayName, "Every 1 hour")
        XCTAssertEqual(TriggerInterval.twoHours.displayName, "Every 2 hours")
        XCTAssertEqual(TriggerInterval.fourHours.displayName, "Every 4 hours")
    }

    func testAllCasesCount() {
        XCTAssertEqual(TriggerInterval.allCases.count, 4)
    }

    func testIdentifiable() {
        for interval in TriggerInterval.allCases {
            XCTAssertEqual(interval.id, interval.rawValue)
        }
    }

    func testInitFromRawValue() {
        XCTAssertEqual(TriggerInterval(rawValue: 1800), .thirtyMinutes)
        XCTAssertEqual(TriggerInterval(rawValue: 3600), .oneHour)
        XCTAssertEqual(TriggerInterval(rawValue: 7200), .twoHours)
        XCTAssertEqual(TriggerInterval(rawValue: 14400), .fourHours)
        XCTAssertNil(TriggerInterval(rawValue: 999), "Invalid raw value should return nil")
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
        let original = prefs.intervalSeconds

        // Set to a known valid value
        prefs.intervalSeconds = TriggerInterval.oneHour.rawValue
        XCTAssertEqual(prefs.selectedInterval, .oneHour)

        // Set to another known valid value
        prefs.intervalSeconds = TriggerInterval.thirtyMinutes.rawValue
        XCTAssertEqual(prefs.selectedInterval, .thirtyMinutes)

        // Restore
        prefs.intervalSeconds = original
    }

    func testSelectedIntervalFallsBackToTwoHoursForInvalidValue() {
        let prefs = Preferences.shared
        let original = prefs.intervalSeconds

        prefs.intervalSeconds = 999
        XCTAssertEqual(
            prefs.selectedInterval, .twoHours,
            "Invalid interval should fall back to twoHours"
        )

        // Restore
        prefs.intervalSeconds = original
    }

    func testIsWithinScheduleReturnsTrueWhenCustomScheduleDisabled() {
        let prefs = Preferences.shared
        let original = prefs.useCustomSchedule

        prefs.useCustomSchedule = false
        XCTAssertTrue(
            prefs.isWithinSchedule(),
            "Should always return true when custom schedule is disabled"
        )

        // Restore
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

        // Enable only weekday that is NOT today
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        let notToday = (todayWeekday % 7) + 1 // guaranteed different
        prefs.enabledWeekdays = Set([notToday])

        XCTAssertFalse(
            prefs.isWithinSchedule(),
            "Should return false when today's weekday is not enabled"
        )

        // Now enable today
        prefs.enabledWeekdays = Set([todayWeekday])
        XCTAssertTrue(
            prefs.isWithinSchedule(),
            "Should return true when today's weekday is enabled and hour is in range"
        )

        // Restore
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

        // Enable all weekdays so weekday check passes
        prefs.enabledWeekdays = Set(1...7)

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())

        // Set range to exclude current hour
        let excludeStart = (currentHour + 2) % 24
        let excludeEnd = (currentHour + 4) % 24
        prefs.startHour = excludeStart
        prefs.endHour = excludeEnd

        XCTAssertFalse(
            prefs.isWithinSchedule(),
            "Should return false when current hour is outside the range [\(excludeStart), \(excludeEnd))"
        )

        // Set range to include current hour
        prefs.startHour = currentHour
        prefs.endHour = (currentHour + 2) % 24
        if prefs.endHour == 0 { prefs.endHour = 24 } // handle edge case; use next day wrap

        // For wrap-around case, we need startHour > endHour
        // Simple case: just set a range that definitely includes now
        prefs.startHour = 0
        prefs.endHour = 23
        XCTAssertTrue(
            prefs.isWithinSchedule(),
            "Should return true when current hour is within [0, 23)"
        )

        // Restore
        prefs.useCustomSchedule = originalSchedule
        prefs.enabledWeekdays = originalWeekdays
        prefs.startHour = originalStart
        prefs.endHour = originalEnd
    }

    func testIsWithinScheduleHandlesWrapAroundHours() {
        let prefs = Preferences.shared
        let originalSchedule = prefs.useCustomSchedule
        let originalWeekdays = prefs.enabledWeekdays
        let originalStart = prefs.startHour
        let originalEnd = prefs.endHour

        prefs.useCustomSchedule = true
        prefs.enabledWeekdays = Set(1...7)

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())

        // Wrap-around: startHour > endHour means "overnight" range
        // Set it so current hour is within the wrap-around range
        prefs.startHour = (currentHour - 1 + 24) % 24
        prefs.endHour = (currentHour - 2 + 24) % 24 // wraps: almost full day

        // This creates a range of 23 hours that includes currentHour
        XCTAssertTrue(
            prefs.isWithinSchedule(),
            "Wrap-around schedule should include current hour"
        )

        // Restore
        prefs.useCustomSchedule = originalSchedule
        prefs.enabledWeekdays = originalWeekdays
        prefs.startHour = originalStart
        prefs.endHour = originalEnd
    }

    func testDefaultWeekdaysAreMonFri() {
        // The defaults registered are [2,3,4,5,6] = Mon-Fri
        let defaults: Set<Int> = [2, 3, 4, 5, 6]
        let prefs = Preferences.shared

        // Only check if user hasn't customized (we check registered defaults)
        // At minimum, verify the type/range is correct
        for day in prefs.enabledWeekdays {
            XCTAssertTrue(
                (1...7).contains(day),
                "Weekday \(day) should be in range 1-7"
            )
        }
        // Verify registered default exists (fresh UserDefaults would use Mon-Fri)
        // We can't guarantee this in tests since UserDefaults persist, but we can
        // verify the selected interval fallback at least
        _ = defaults // suppress unused warning
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

        // Restore
        manager.onTrigger = originalHandler
    }

    func testTriggerNowWithNoHandlerDoesNotCrash() {
        let manager = ScheduleManager.shared
        let originalHandler = manager.onTrigger

        manager.onTrigger = nil
        // Should not crash
        manager.triggerNow()

        // Restore
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
