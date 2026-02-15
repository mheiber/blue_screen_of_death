import Foundation
import Combine

/// Interval options for automatic blue screen triggers
enum TriggerInterval: Int, CaseIterable, Identifiable {
    case thirtyMinutes = 1800
    case oneHour = 3600
    case twoHours = 7200
    case fourHours = 14400

    var id: Int { rawValue }

    var displayName: String {
        switch self {
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

    var selectedInterval: TriggerInterval {
        TriggerInterval(rawValue: intervalSeconds) ?? .twoHours
    }

    private init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.intervalSeconds: TriggerInterval.twoHours.rawValue,
            Keys.launchAtLogin: false,
            Keys.useCustomSchedule: false,
            Keys.enabledWeekdays: [2, 3, 4, 5, 6], // Mon-Fri
            Keys.startHour: 9,
            Keys.endHour: 17
        ])

        self.isEnabled = defaults.bool(forKey: Keys.isEnabled)
        self.intervalSeconds = defaults.integer(forKey: Keys.intervalSeconds)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.useCustomSchedule = defaults.bool(forKey: Keys.useCustomSchedule)

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
            // Wraps around midnight
            return hour >= startHour || hour < endHour
        }
    }
}
