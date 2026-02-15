import Foundation

/// Data for the modern ":(" style blue screen
struct ModernScreenData {
    let stopCode: String
    let percentage: Int
}

/// Generates randomized, believable crash dump text for the blue screen overlay.
/// All text is completely original — no trademarked terms. Uses "Winsome" branding.
struct CrashDumpGenerator {

    // MARK: - Easter egg hex codes

    private static let easterEggCodes: [UInt64] = [
        0xDEADBEEF,
        0xCAFEBABE,
        0xBAADF00D,
        0xFEEDFACE,
        0xC0FFEE,
        0xBEEFCAFE,
        0xFACEFEED,
        0xD15EA5E,
        0xBADCAFE,
        0xACCE55ED,
        0xC0DED00D,
        0xACEDB00C,
    ]

    // MARK: - Stop codes

    private static let stopCodes: [String] = [
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

    // MARK: - Fake driver names (original, "ws" prefix for Winsome)

    private static let driverNames: [String] = [
        "WSCMDCON.SYS",
        "WSKRNL.SYS",
        "WSDISP.SYS",
        "WSPOOL.SYS",
        "WSNVME.SYS",
        "WSUSB.SYS",
        "WSAUDIO.SYS",
        "WSVIDEO.SYS",
        "WSNET.SYS",
        "WSRAID.SYS",
        "WSINPUT.SYS",
        "WSPOWER.SYS",
        "WSCACHE.SYS",
        "WSDISK.SYS",
        "WSSERIAL.SYS",
        "WSPRINT.SYS",
    ]

    // MARK: - Classic dump DLL/module table entries

    private static let dumpModules: [(base: String, name: String)] = [
        ("80100000", "wsoskrnl.exe"),
        ("80400000", "wsl.dll"),
        ("80010000", "wsapi.sys"),
        ("80013000", "WSCIPORT.SYS"),
        ("80006000", "WSDISK.SYS"),
        ("80026000", "wsfs.sys"),
        ("800A0000", "ws32k.sys"),
        ("F8510000", "WSVIDEO.SYS"),
        ("F84F0000", "WSDISP.SYS"),
        ("F84D0000", "WSAUDIO.SYS"),
        ("F84B0000", "WSUSB.SYS"),
        ("F8490000", "WSKRNL.SYS"),
        ("F8470000", "WSCMDCON.SYS"),
        ("F8450000", "WSPOOL.SYS"),
        ("F8430000", "WSNET.SYS"),
        ("F8410000", "WSNVME.SYS"),
        ("F83F0000", "WSRAID.SYS"),
        ("F83D0000", "WSINPUT.SYS"),
        ("F83B0000", "WSPOWER.SYS"),
        ("F8390000", "WSCACHE.SYS"),
        ("F8370000", "wsdll.dll"),
        ("F8350000", "WSPRINT.SYS"),
        ("F8330000", "WSSERIAL.SYS"),
        ("F8310000", "WSBIOS.SYS"),
    ]

    // MARK: - Mojibake character sets

    private static let boxDrawing: [Character] = Array("─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬")
    private static let katakana: [Character] = Array("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン")
    private static let cyrillic: [Character] = Array("ФХЦЧШЩЪЫЬЭЮЯБВГДЕЖЗИКЛМНОП")
    private static let accented: [Character] = Array("àáâãäåæçèéêëìíîïðñòóôõöùúûüý")
    private static let symbols: [Character] = Array("¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿")

    // MARK: - Generation

    /// Generate crash dump text for a given screen style.
    /// For modern style, use `generateModernData()` instead.
    static func generate(style: ScreenStyle) -> String {
        switch style {
        case .modern:
            // Modern style uses structured data; return a simple fallback text
            let data = generateModernData()
            return "Stop code: \(data.stopCode)\n\(data.percentage)% complete"
        case .classic:
            return generateClassic()
        case .classicDump:
            return generateClassicDump()
        case .mojibake:
            return generateMojibake()
        case .cyberwin2070:
            // These styles handle their own text generation
            let data = generateModernData()
            return "Stop code: \(data.stopCode)\n\(data.percentage)% complete"
        }
    }

    /// Generate structured data for the modern ":(" style screen
    static func generateModernData() -> ModernScreenData {
        let stopCode = stopCodes.randomElement()!
        let percentage = Int.random(in: 0...99)
        return ModernScreenData(stopCode: stopCode, percentage: percentage)
    }

    // MARK: - Classic Style (XP era)

    private static func generateClassic() -> String {
        let driver = driverNames.randomElement()!
        let stopCode = stopCodes.randomElement()!
        let eggs = easterEggCodes.shuffled()

        let stopHex = hex32(eggs[0])
        let param1 = hex32(eggs[1])
        let param2 = hex32(UInt64(UInt32.random(in: 0...1)))
        let param3 = hex32(eggs[2])
        let param4 = hex32(0)

        let baseAddr = randomHex8Upper()
        let addrStamp = String(format: "%08x", UInt32.random(in: 0x3D000000...0x3DFFFFFF))

        var lines: [String] = []
        lines.append(L("bsod.classic.problemDetected"))
        lines.append(L("bsod.classic.toYourComputer"))
        lines.append("")
        lines.append(L("bsod.classic.causedBy", driver))
        lines.append("")
        lines.append(stopCode)
        lines.append("")
        lines.append(L("bsod.classic.firstTime"))
        lines.append(L("bsod.classic.restartComputer"))
        lines.append(L("bsod.classic.theseSteps"))
        lines.append("")
        lines.append(L("bsod.classic.checkHardware"))
        lines.append(L("bsod.classic.newInstallation"))
        lines.append(L("bsod.classic.updatesNeeded"))
        lines.append("")
        lines.append(L("bsod.classic.continueProblems"))
        lines.append(L("bsod.classic.orSoftware"))
        lines.append(L("bsod.classic.safeMode"))
        lines.append(L("bsod.classic.pressF8"))
        lines.append(L("bsod.classic.selectSafeMode"))
        lines.append("")
        lines.append(L("bsod.classic.techInfo"))
        lines.append("")
        lines.append("*** STOP: 0x\(stopHex) (0x\(param1),0x\(param2),0x\(param3),0x\(param4))")
        lines.append("")
        lines.append("***   \(driver) - Address \(param3) base at \(baseAddr), DateStamp \(addrStamp)")

        return lines.joined(separator: "\n")
    }

    // MARK: - Classic Dump Style (NT4/2000 era)

    private static func generateClassicDump() -> String {
        let stopCode = stopCodes.randomElement()!
        let eggs = easterEggCodes.shuffled()

        let stopHex = hex32(eggs[0])
        let param1 = String(format: "%08X", UInt32.random(in: 0xFC000000...0xFCFFFFFF))
        let param2 = String(format: "%08X", UInt32.random(in: 0...0xFF))
        let param3 = String(format: "%08X", 0)
        let param4 = String(format: "%08X", 0)

        let sysver = String(format: "0xf0000%03x", UInt32.random(in: 0x400...0x4FF))
        let buildNum = Int.random(in: 1000...2200)

        var lines: [String] = []
        lines.append("*** STOP: 0x\(stopHex) (0x\(param1),0x\(param2),0x\(param3),0x\(param4))")
        lines.append(stopCode)
        lines.append("")
        lines.append("p5-0000 irql:2  SYSVER \(sysver)")
        lines.append("")

        // Two-column DLL table
        lines.append("Dll Base DateStmp - Name          Dll Base DateStmp - Name")

        let modules = dumpModules.shuffled()
        let halfCount = modules.count / 2
        for row in 0..<halfCount {
            let left = modules[row]
            let rightIdx = row + halfCount
            let leftStamp = String(format: "%08x", UInt32.random(in: 0x2F000000...0x3FFFFFFF))
            let rightStamp = String(format: "%08x", UInt32.random(in: 0x2F000000...0x3FFFFFFF))

            if rightIdx < modules.count {
                let right = modules[rightIdx]
                let leftEntry = "\(left.base) \(leftStamp) - \(left.name)"
                let rightEntry = "\(right.base) \(rightStamp) - \(right.name)"
                let padding = String(repeating: " ", count: max(1, 42 - leftEntry.count))
                lines.append("\(leftEntry)\(padding)\(rightEntry)")
            } else {
                lines.append("\(left.base) \(leftStamp) - \(left.name)")
            }
        }

        lines.append("")
        lines.append("Address  dword_dump                                         Build [\(buildNum)]                           - Name")

        // Hex dump rows with easter eggs sprinkled in
        let dumpModuleSubset = modules.prefix(20)
        var eggIdx = 0
        for mod in dumpModuleSubset {
            var dwords: [String] = []
            for col in 0..<6 {
                // Sprinkle in easter eggs occasionally
                if eggIdx < eggs.count && col == Int.random(in: 0...5) && Bool.random() {
                    dwords.append(hex32(eggs[eggIdx]))
                    eggIdx += 1
                } else {
                    dwords.append(String(format: "%08x", UInt32.random(in: 0...UInt32.max)))
                }
            }
            let addr = String(format: "%08x", UInt32.random(in: 0xFC000000...0xFEFFFFFF))
            let dwordStr = dwords.joined(separator: " ")
            lines.append("\(addr) \(dwordStr) - \(mod.name)")
        }

        lines.append("")
        lines.append(L("bsod.classicDump.recovery1"))
        lines.append(L("bsod.classicDump.recovery2"))
        lines.append(L("bsod.classicDump.recovery3"))

        return lines.joined(separator: "\n")
    }

    // MARK: - Mojibake Style

    /// All mojibake corruption characters combined into one pool.
    private static let corruptionPool: [Character] = boxDrawing + katakana + cyrillic + accented + symbols

    /// Generates mojibake by corrupting the localized classic BSOD text.
    /// The base text comes from the user's current language, then characters
    /// are randomly replaced with wrong-encoding equivalents — simulating
    /// real mojibake (text displayed in the wrong character encoding).
    private static func generateMojibake() -> String {
        // Build the localized classic BSOD as the base text
        let baseText = generateClassicAsBase()

        // Corrupt approximately 55-70% of characters
        let corruptionRate = Double.random(in: 0.55...0.70)

        var result: [Character] = []
        for char in baseText {
            if char == "\n" {
                // Preserve line breaks to maintain structure
                result.append(char)
            } else if char == " " && Double.random(in: 0...1) < 0.3 {
                // Sometimes corrupt spaces too
                result.append(corruptionPool.randomElement()!)
            } else if Double.random(in: 0...1) < corruptionRate {
                // Replace with a random corruption character
                result.append(corruptionPool.randomElement()!)
                // Occasionally insert an extra garbled character
                if Double.random(in: 0...1) < 0.15 {
                    result.append(corruptionPool.randomElement()!)
                }
            } else {
                result.append(char)
            }
        }

        // Pad to at least 40 lines with pure garbled text
        var lines = String(result).components(separatedBy: "\n")
        while lines.count < 40 {
            let lineLen = Int.random(in: 20...80)
            let garbledLine = (0..<lineLen).map { _ in corruptionPool.randomElement()! }
            lines.append(String(garbledLine))
        }

        return lines.joined(separator: "\n")
    }

    /// Generates the classic BSOD text as a base for mojibake corruption.
    /// Uses the current localized strings.
    private static func generateClassicAsBase() -> String {
        let driver = driverNames.randomElement()!
        let stopCode = stopCodes.randomElement()!
        let eggs = easterEggCodes.shuffled()

        let stopHex = hex32(eggs[0])
        let param1 = hex32(eggs[1])
        let param2 = hex32(UInt64(UInt32.random(in: 0...1)))
        let param3 = hex32(eggs[2])
        let param4 = hex32(0)

        var lines: [String] = []
        lines.append(L("bsod.classic.problemDetected"))
        lines.append(L("bsod.classic.toYourComputer"))
        lines.append("")
        lines.append(L("bsod.classic.causedBy", driver))
        lines.append("")
        lines.append(stopCode)
        lines.append("")
        lines.append(L("bsod.classic.firstTime"))
        lines.append(L("bsod.classic.restartComputer"))
        lines.append(L("bsod.classic.theseSteps"))
        lines.append("")
        lines.append(L("bsod.classic.checkHardware"))
        lines.append(L("bsod.classic.newInstallation"))
        lines.append(L("bsod.classic.updatesNeeded"))
        lines.append("")
        lines.append(L("bsod.classic.continueProblems"))
        lines.append(L("bsod.classic.orSoftware"))
        lines.append(L("bsod.classic.safeMode"))
        lines.append(L("bsod.classic.pressF8"))
        lines.append(L("bsod.classic.selectSafeMode"))
        lines.append("")
        lines.append(L("bsod.classic.techInfo"))
        lines.append("")
        lines.append("*** STOP: 0x\(stopHex) (0x\(param1),0x\(param2),0x\(param3),0x\(param4))")

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func hex32(_ value: UInt64) -> String {
        String(format: "%08X", UInt32(value & 0xFFFFFFFF))
    }

    private static func randomHex8Upper() -> String {
        String(format: "%08X", UInt32.random(in: 0...UInt32.max))
    }
}
