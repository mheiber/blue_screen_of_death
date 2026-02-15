import Foundation
import Combine

/// Schedules a daily lunch reminder trigger, independent of the main interval timer.
final class LunchReminderScheduler {
    static let shared = LunchReminderScheduler()

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let preferences = Preferences.shared

    /// Called when the lunch reminder fires
    var onTrigger: (() -> Void)?

    private init() {
        // React to lunch reminder preference changes
        preferences.$lunchReminderEnabled
            .combineLatest(
                preferences.$lunchReminderHour,
                preferences.$lunchReminderMinute
            )
            .sink { [weak self] _ in
                self?.reschedule()
            }
            .store(in: &cancellables)
    }

    func start() {
        reschedule()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func reschedule() {
        timer?.invalidate()
        timer = nil

        guard preferences.lunchReminderEnabled else { return }

        scheduleNext()
    }

    private func scheduleNext() {
        let calendar = Calendar.current
        let now = Date()

        // Build the target time for today
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = preferences.lunchReminderHour
        components.minute = preferences.lunchReminderMinute
        components.second = 0

        guard var target = calendar.date(from: components) else { return }

        // If the target time has already passed today, schedule for tomorrow
        if target <= now {
            target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
        }

        let interval = target.timeIntervalSince(now)

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.fire()
        }
    }

    private func fire() {
        guard preferences.lunchReminderEnabled else { return }
        onTrigger?()
        // Schedule for the next day
        scheduleNext()
    }
}
