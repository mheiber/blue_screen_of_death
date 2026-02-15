import Foundation

/// Generates randomized, believable crash dump text for the blue screen overlay.
/// All text is completely original — no trademarked terms.
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
        0xDEFEC8ED,
        0xC0DED00D,
        0xACEDB00C,
    ]

    // MARK: - Stop codes (generic computing terms)

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

    // MARK: - Fake driver/module names

    private static let moduleNames: [String] = [
        "kernel_task.sys",
        "display_mgr.sys",
        "awareness_drv.sys",
        "focus_stack.sys",
        "breath_timer.sys",
        "eye_rest.sys",
        "mindful_core.sys",
        "posture_mon.sys",
        "hydration_io.sys",
        "wellbeing_fs.sys",
        "stretch_sched.sys",
        "calm_process.sys",
        "serenity_pool.sys",
        "zen_dispatch.sys",
    ]

    // MARK: - Mindfulness messages

    private static let mindfulnessMessages: [String] = [
        "Take a deep breath. Look at something 20 feet away for 20 seconds.",
        "Close your eyes for a moment. Notice the sounds around you.",
        "Roll your shoulders back. Unclench your jaw. You are safe.",
        "Place both feet flat on the floor. Feel the ground beneath you.",
        "Take three slow breaths. In through the nose, out through the mouth.",
        "Look away from the screen. Let your eyes rest on something distant.",
        "Notice where you're holding tension. Breathe into that space.",
        "You are not your inbox. You are not your to-do list. You are here.",
        "Drink some water. Stretch your hands. Wiggle your fingers.",
        "The work will be there when you return. This moment is for you.",
    ]

    // MARK: - Fake process names for stack trace

    private static let processNames: [String] = [
        "SYSTEM",
        "KERNEL",
        "SCHEDULER",
        "IDLE_PROCESS",
        "MEMORY_MANAGER",
        "IO_SUBSYSTEM",
        "DISPLAY_COMPOSITOR",
        "INPUT_HANDLER",
        "POWER_MANAGER",
        "CACHE_WORKER",
    ]

    // MARK: - Fake function names for stack trace

    private static let functionNames: [String] = [
        "KiDispatchInterrupt",
        "MmAccessFault",
        "IoCallDriver",
        "KeWaitForSingleObject",
        "PspProcessDelete",
        "ExAllocatePoolWithTag",
        "ObDereferenceObject",
        "CcFlushCache",
        "FsRtlNotifyFullChangeDirectory",
        "RtlpBreakWithStatusInstruction",
        "KeBugCheckEx",
        "HalReturnToFirmware",
        "NtCreateSection",
        "ExpWorkerThread",
        "PspSystemThreadStartup",
    ]

    // MARK: - Generation

    /// Generate a complete, randomized crash dump screen text.
    static func generate() -> String {
        var lines: [String] = []
        let stopCode = stopCodes.randomElement()!
        let easterEggs = easterEggCodes.shuffled()
        let module = moduleNames.randomElement()!
        let mindfulness = mindfulnessMessages.randomElement()!
        let progress = Int.random(in: 0...99)

        // Header
        lines.append("A problem has been detected and the system has been")
        lines.append("shut down to prevent damage to your awareness practice.")
        lines.append("")
        lines.append(stopCode)
        lines.append("")

        // First mindfulness block
        lines.append("If this is the first time you have seen this Stop error screen,")
        lines.append("take a deep breath. If this screen appears again, follow")
        lines.append("these steps:")
        lines.append("")
        lines.append("Check to make sure you have had enough water today.")
        lines.append("If this is a new reminder, ask your body what it needs.")
        lines.append("If problems continue, consider a short walk outside.")
        lines.append("")

        // Technical info
        lines.append("Technical information:")
        lines.append("")
        let codes = (0...4).map { "0x\(hex(easterEggs[$0]))" }
        lines.append("*** STOP: \(codes[0]) (\(codes[1]), \(codes[2]), \(codes[3]), \(codes[4]))")
        lines.append("")
        lines.append("***   \(module) - Address 0x\(hex(easterEggs[5])) base at 0x\(randomHex8())")
        lines.append("")

        // Stack trace
        lines.append("Stack trace:")
        let traceCount = Int.random(in: 4...7)
        for _ in 0..<traceCount {
            let process = processNames.randomElement()!
            let function = functionNames.randomElement()!
            lines.append("  \(process)!\(function)+0x\(randomHexShort()) [0x\(randomHex8())]")
        }
        lines.append("")

        // Mindfulness data collection
        lines.append("Collecting mindfulness data for analysis...")
        lines.append("Initializing breath awareness module... done")
        lines.append("Scanning for tension patterns......... done")
        lines.append("Dumping stress buffers to /dev/calm... \(progress)% complete")
        lines.append("")

        // The main mindfulness message
        lines.append("*** \(mindfulness) ***")
        lines.append("")

        // Physical memory dump
        lines.append("Beginning dump of physical awareness...")
        lines.append("Physical awareness dump complete.")
        lines.append("Contact your wellness practice or take a stretch break")
        lines.append("for further assistance.")
        lines.append("")

        // Footer
        lines.append("Press any key to return to reality")

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func hex(_ value: UInt64) -> String {
        String(format: "%08X", value)
    }

    private static func randomHex8() -> String {
        String(format: "%08X", UInt32.random(in: 0...UInt32.max))
    }

    private static func randomHexShort() -> String {
        String(format: "%03X", UInt16.random(in: 0...0xFFF))
    }
}
