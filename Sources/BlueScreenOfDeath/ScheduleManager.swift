import Foundation
import Combine

/// Manages the timer that triggers blue screen displays at the configured interval
final class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let preferences = Preferences.shared

    /// Called when a blue screen should be triggered
    var onTrigger: (() -> Void)?

    @Published private(set) var nextTriggerDate: Date?

    private init() {
        // React to preference changes
        preferences.$isEnabled
            .combineLatest(
                preferences.$selectedIntervalRaw,
                preferences.$useCustomInterval,
                preferences.$customMinutes
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
        nextTriggerDate = nil
    }

    func reschedule() {
        timer?.invalidate()
        timer = nil

        guard preferences.isEnabled else {
            nextTriggerDate = nil
            return
        }

        scheduleNext()
    }

    /// Schedule the next trigger. For random intervals, each fire picks a new random delay.
    private func scheduleNext() {
        let interval = TimeInterval(preferences.effectiveIntervalSeconds)
        nextTriggerDate = Date().addingTimeInterval(interval)

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.fire()
        }
    }

    private func fire() {
        guard preferences.isEnabled else { return }

        if preferences.isWithinSchedule() {
            let suppressed = preferences.suppressDuringScreenShare
                && ScreenShareDetector.shouldSuppress(suppressDuringCalls: true)
            if !suppressed {
                onTrigger?()
            }
        }

        // Schedule next (re-rolls random intervals each time)
        scheduleNext()
    }

    /// Trigger immediately (manual trigger from menu)
    func triggerNow() {
        onTrigger?()
    }
}
