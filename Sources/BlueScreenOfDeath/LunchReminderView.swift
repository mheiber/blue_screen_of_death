import SwiftUI

/// SwiftUI view for configuring the lunch reminder time
struct LunchReminderView: View {
    @ObservedObject private var preferences = Preferences.shared

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = preferences.lunchReminderHour
                components.minute = preferences.lunchReminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                preferences.lunchReminderHour = components.hour ?? 11
                preferences.lunchReminderMinute = components.minute ?? 55
            }
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Lunch Reminder")
                .font(.headline)

            Toggle("Enable Lunch Reminder", isOn: $preferences.lunchReminderEnabled)

            if preferences.lunchReminderEnabled {
                DatePicker("Time:", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .frame(maxWidth: 200)
            }

            Text("Blue screen will remind you when it is lunch time.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(width: 280)
    }
}
