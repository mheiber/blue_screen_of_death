import SwiftUI

struct CustomScheduleView: View {
    @ObservedObject private var preferences = Preferences.shared

    private let weekdays: [(Int, String)] = [
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday"),
        (1, "Sunday")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Use Custom Schedule", isOn: $preferences.useCustomSchedule)
                .font(.headline)

            if preferences.useCustomSchedule {
                GroupBox("Active Days") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(weekdays, id: \.0) { day in
                            Toggle(day.1, isOn: weekdayBinding(for: day.0))
                        }
                    }
                    .padding(4)
                }

                GroupBox("Active Hours") {
                    HStack {
                        Picker("From", selection: $preferences.startHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .frame(maxWidth: 140)

                        Picker("To", selection: $preferences.endHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .frame(maxWidth: 140)
                    }
                    .padding(4)
                }

                Text("Blue screen reminders will only trigger during the selected days and hours.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 340, height: 400)
    }

    private func weekdayBinding(for day: Int) -> Binding<Bool> {
        Binding(
            get: { preferences.enabledWeekdays.contains(day) },
            set: { enabled in
                if enabled {
                    preferences.enabledWeekdays.insert(day)
                } else {
                    preferences.enabledWeekdays.remove(day)
                }
            }
        )
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}
