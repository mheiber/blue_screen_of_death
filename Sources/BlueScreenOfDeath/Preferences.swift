import Foundation
import Combine

/// Screen style options for the blue screen overlay
enum ScreenStyle: String, CaseIterable, Identifiable {
    case modern = "modern"
    case classic = "classic"
    case classicDump = "classicDump"
    case mojibake = "mojibake"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .modern: return "Modern"
        case .classic: return "Classic"
        case .classicDump: return "Classic Dump"
        case .mojibake: return "Mojibake"
        }
    }
}

/// Interval options for automatic blue screen triggers
enum TriggerInterval: Int, CaseIterable, Identifiable {
    case twentyMinutes = 1200
    case thirtyMinutes = 1800
    case oneHour = 3600
    case twoHours = 7200
    case fourHours = 14400

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .twentyMinutes: return "Every 20 minutes"
        case .thirtyMinutes: return "Every 30 minutes"
        case .oneHour: return "Every 1 hour"
        case .twoHours: return "Every 2 hours"
        case .fourHours: return "Every 4 hours"
        }
    }
}

/// Manages user preferences backed by UserDefaults
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let intervalSeconds = "intervalSeconds"
        static let launchAtLogin = "launchAtLogin"
        static let enabledWeekdays = "enabledWeekdays"
        static let startHour = "startHour"
        static let endHour = "endHour"
        static let useCustomSchedule = "useCustomSchedule"
        static let selectedStyleRaw = "selectedStyleRaw"
        static let customMinutes = "customMinutes"
        static let useCustomInterval = "useCustomInterval"
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var intervalSeconds: Int {
        didSet { defaults.set(intervalSeconds, forKey: Keys.intervalSeconds) }
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

    /// Returns the selected style, or nil if "random"
    var selectedStyle: ScreenStyle? {
        ScreenStyle(rawValue: selectedStyleRaw)
    }

    /// Resolves the style to use: returns selectedStyle if set, otherwise random pick
    func resolveStyle() -> ScreenStyle {
        selectedStyle ?? ScreenStyle.allCases.randomElement()!
    }

    var selectedInterval: TriggerInterval {
        TriggerInterval(rawValue: intervalSeconds) ?? .twoHours
    }

    /// Effective interval in seconds, accounting for custom interval
    var effectiveIntervalSeconds: Int {
        if useCustomInterval {
            return customMinutes * 60
        }
        return intervalSeconds
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
            Keys.intervalSeconds: TriggerInterval.twoHours.rawValue,
            Keys.launchAtLogin: false,
            Keys.useCustomSchedule: false,
            Keys.enabledWeekdays: [2, 3, 4, 5, 6],
            Keys.startHour: 9,
            Keys.endHour: 17,
            Keys.selectedStyleRaw: "modern",
            Keys.customMinutes: 20,
            Keys.useCustomInterval: false,
        ])

        self.isEnabled = defaults.bool(forKey: Keys.isEnabled)
        self.intervalSeconds = defaults.integer(forKey: Keys.intervalSeconds)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.useCustomSchedule = defaults.bool(forKey: Keys.useCustomSchedule)
        self.selectedStyleRaw = defaults.string(forKey: Keys.selectedStyleRaw) ?? "modern"
        self.customMinutes = defaults.integer(forKey: Keys.customMinutes)
        self.useCustomInterval = defaults.bool(forKey: Keys.useCustomInterval)

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
