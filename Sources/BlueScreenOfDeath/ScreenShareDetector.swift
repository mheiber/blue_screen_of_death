import AppKit

/// Detects whether screen sharing or video conferencing is likely active,
/// so the blue screen overlay can be suppressed to avoid embarrassment.
struct ScreenShareDetector {

    /// Bundle IDs that definitively indicate screen sharing/recording is active.
    static let definiteIndicatorBundleIDs: Set<String> = [
        "com.apple.screensharing",
        "com.apple.screencaptureui",
    ]

    /// Bundle IDs of conferencing apps that might be screen sharing.
    static let conferencingBundleIDs: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams",
        "com.microsoft.teams2",
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "com.cisco.webexmeetingsapp",
        "com.webex.meetingmanager",
        "com.logmein.GoToMeeting",
        "com.loom.desktop",
        "com.obsproject.obs-studio",
        "com.apple.FaceTime",
        "com.skype.skype",
        "com.apple.QuickTimePlayerX",
    ]

    /// Process names that indicate active screen sharing (not just the app being open).
    static let activeSharingProcessNames: Set<String> = [
        "CptHost",
    ]

    /// Check if screen sharing suppression should activate.
    /// - Parameter runningBundleIDs: Bundle IDs of running apps (injectable for testing)
    /// - Parameter runningProcessNames: Process names of running apps (injectable for testing)
    /// - Parameter suppressDuringCalls: If true, also suppress when conferencing apps are running
    static func shouldSuppress(
        runningBundleIDs: Set<String>,
        runningProcessNames: Set<String>,
        suppressDuringCalls: Bool
    ) -> Bool {
        if !definiteIndicatorBundleIDs.isDisjoint(with: runningBundleIDs) {
            return true
        }

        if !activeSharingProcessNames.isDisjoint(with: runningProcessNames) {
            return true
        }

        if suppressDuringCalls && !conferencingBundleIDs.isDisjoint(with: runningBundleIDs) {
            return true
        }

        return false
    }

    /// Convenience: check using live NSWorkspace data.
    static func shouldSuppress(suppressDuringCalls: Bool) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let bundleIDs = Set(runningApps.compactMap { $0.bundleIdentifier })
        let processNames = Set(runningApps.compactMap { $0.localizedName })
        return shouldSuppress(
            runningBundleIDs: bundleIDs,
            runningProcessNames: processNames,
            suppressDuringCalls: suppressDuringCalls
        )
    }
}
