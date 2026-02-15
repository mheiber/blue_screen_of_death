import Foundation
import Combine

/// Screen style options for the blue screen overlay
enum ScreenStyle: String, CaseIterable, Identifiable {
    case modern = "modern"
    case classic = "classic"
    case classicDump = "classicDump"
    case mojibake = "mojibake"
    case synthwave = "synthwave"
    case paperclips = "paperclips"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .modern: return "Modern"
        case .classic: return "Classic"
        case .classicDump: return "Classic Dump"
        case .mojibake: return "Mojibake"
        case .synthwave: return "Synthwave"
        case .paperclips: return "Paperclips"
        }
    }
}

/// Interval options for automatic blue screen triggers
enum TriggerInterval: String, CaseIterable, Identifiable {
    case twentyMinutes = "twentyMinutes"
    case oneHour = "oneHour"
    case twoHours = "twoHours"
    case threeHours = "threeHours"
    case randomShort = "randomShort"
    case randomLong = "randomLong"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twentyMinutes: return "Every 20 minutes"
        case .oneHour: return "Every hour"
        case .twoHours: return "Every 2 hours"
        case .threeHours: return "Every 3 hours"
        case .randomShort: return "Random (~1.5 hours)"
        case .randomLong: return "Random (~3 hours)"
        }
    }

    /// Returns the interval in seconds. Random options return a randomized value.
    var intervalSeconds: Int {
        switch self {
        case .twentyMinutes: return 1200
        case .oneHour: return 3600
        case .twoHours: return 7200
        case .threeHours: return 10800
        case .randomShort:
            // Random between 45 min and 2 hr 15 min (mean ~1.5 hr)
            return Int.random(in: 2700...8100)
        case .randomLong:
            // Random between 1.5 hr and 4.5 hr (mean ~3 hr)
            return Int.random(in: 5400...16200)
        }
    }
}

/// Manages user preferences backed by UserDefaults
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let selectedIntervalRaw = "selectedIntervalRaw"
        static let launchAtLogin = "launchAtLogin"
        static let enabledWeekdays = "enabledWeekdays"
        static let startHour = "startHour"
        static let endHour = "endHour"
        static let useCustomSchedule = "useCustomSchedule"
        static let selectedStyleRaw = "selectedStyleRaw"
        static let customMinutes = "customMinutes"
        static let useCustomInterval = "useCustomInterval"
        static let lunchReminderEnabled = "lunchReminderEnabled"
        static let lunchReminderHour = "lunchReminderHour"
        static let lunchReminderMinute = "lunchReminderMinute"
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var selectedIntervalRaw: String {
        didSet { defaults.set(selectedIntervalRaw, forKey: Keys.selectedIntervalRaw) }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var useCustomSchedule: Bool {
        didSet { defaults.set(useCustomSchedule, forKey: Keys.useCustomSchedule) }
    }

    /// Weekday mask: 1=Sunday, 2=Monday, ..., 7=Saturday
    @Published var enabledWeekdays: Set<Int> {
        didSet { defaults.set(Array(enabledWeekdays), forKey: Keys.enabledWeekdays) }
    }

    /// Start hour for custom schedule (0-23)
    @Published var startHour: Int {
        didSet { defaults.set(startHour, forKey: Keys.startHour) }
    }

    /// End hour for custom schedule (0-23)
    @Published var endHour: Int {
        didSet { defaults.set(endHour, forKey: Keys.endHour) }
    }

    /// Raw style string: one of ScreenStyle.rawValue or "random"
    @Published var selectedStyleRaw: String {
        didSet { defaults.set(selectedStyleRaw, forKey: Keys.selectedStyleRaw) }
    }

    /// Custom interval in minutes (1-240)
    @Published var customMinutes: Int {
        didSet {
            let clamped = min(max(customMinutes, 1), 240)
            if clamped != customMinutes { customMinutes = clamped }
            defaults.set(clamped, forKey: Keys.customMinutes)
        }
    }

    /// Whether to use custom interval instead of preset
    @Published var useCustomInterval: Bool {
        didSet { defaults.set(useCustomInterval, forKey: Keys.useCustomInterval) }
    }

    /// Whether the lunch reminder is enabled (independent of main timer)
    @Published var lunchReminderEnabled: Bool {
        didSet { defaults.set(lunchReminderEnabled, forKey: Keys.lunchReminderEnabled) }
    }

    /// Lunch reminder hour (0-23), default 11
    @Published var lunchReminderHour: Int {
        didSet { defaults.set(lunchReminderHour, forKey: Keys.lunchReminderHour) }
    }

    /// Lunch reminder minute (0-59), default 55
    @Published var lunchReminderMinute: Int {
        didSet { defaults.set(lunchReminderMinute, forKey: Keys.lunchReminderMinute) }
    }

    /// Returns the selected style, or nil if "random"
    var selectedStyle: ScreenStyle? {
        ScreenStyle(rawValue: selectedStyleRaw)
    }

    /// Resolves the style to use: returns selectedStyle if set, otherwise random pick
    func resolveStyle() -> ScreenStyle {
        selectedStyle ?? ScreenStyle.allCases.randomElement()!
    }

    var selectedInterval: TriggerInterval {
        TriggerInterval(rawValue: selectedIntervalRaw) ?? .oneHour
    }

    /// Effective interval in seconds, accounting for custom interval and random options
    var effectiveIntervalSeconds: Int {
        if useCustomInterval {
            return customMinutes * 60
        }
        return selectedInterval.intervalSeconds
    }

    /// Display name for the current interval setting
    var intervalDisplayName: String {
        if useCustomInterval {
            return "Every \(customMinutes) min"
        }
        return selectedInterval.displayName
    }

    private init() {
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.selectedIntervalRaw: TriggerInterval.oneHour.rawValue,
            Keys.launchAtLogin: false,
            Keys.useCustomSchedule: false,
            Keys.enabledWeekdays: [2, 3, 4, 5, 6],
            Keys.startHour: 9,
            Keys.endHour: 17,
            Keys.selectedStyleRaw: "modern",
            Keys.customMinutes: 20,
            Keys.useCustomInterval: false,
            Keys.lunchReminderEnabled: false,
            Keys.lunchReminderHour: 11,
            Keys.lunchReminderMinute: 55,
        ])

        self.isEnabled = defaults.bool(forKey: Keys.isEnabled)
        self.selectedIntervalRaw = defaults.string(forKey: Keys.selectedIntervalRaw) ?? TriggerInterval.oneHour.rawValue
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.useCustomSchedule = defaults.bool(forKey: Keys.useCustomSchedule)
        self.selectedStyleRaw = defaults.string(forKey: Keys.selectedStyleRaw) ?? "modern"
        self.customMinutes = defaults.integer(forKey: Keys.customMinutes)
        self.useCustomInterval = defaults.bool(forKey: Keys.useCustomInterval)
        self.lunchReminderEnabled = defaults.bool(forKey: Keys.lunchReminderEnabled)
        self.lunchReminderHour = defaults.integer(forKey: Keys.lunchReminderHour)
        self.lunchReminderMinute = defaults.integer(forKey: Keys.lunchReminderMinute)

        if let weekdays = defaults.array(forKey: Keys.enabledWeekdays) as? [Int] {
            self.enabledWeekdays = Set(weekdays)
        } else {
            self.enabledWeekdays = [2, 3, 4, 5, 6]
        }

        self.startHour = defaults.integer(forKey: Keys.startHour)
        self.endHour = defaults.integer(forKey: Keys.endHour)
    }

    /// Check if the current time falls within the custom schedule
    func isWithinSchedule() -> Bool {
        guard useCustomSchedule else { return true }

        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)

        guard enabledWeekdays.contains(weekday) else { return false }

        if startHour <= endHour {
            return hour >= startHour && hour < endHour
        } else {
            return hour >= startHour || hour < endHour
        }
    }
}
