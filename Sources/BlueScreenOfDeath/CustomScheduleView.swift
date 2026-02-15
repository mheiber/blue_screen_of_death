import SwiftUI

struct CustomScheduleView: View {
    @ObservedObject private var preferences = Preferences.shared

    private let weekdays: [(Int, String)] = [
        (2, "day.monday"),
        (3, "day.tuesday"),
        (4, "day.wednesday"),
        (5, "day.thursday"),
        (6, "day.friday"),
        (7, "day.saturday"),
        (1, "day.sunday")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(L("schedule.useCustom"), isOn: $preferences.useCustomSchedule)
                .font(.headline)

            if preferences.useCustomSchedule {
                GroupBox(L("schedule.activeDays")) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(weekdays, id: \.0) { day in
                            Toggle(L(day.1), isOn: weekdayBinding(for: day.0))
                        }
                    }
                    .padding(4)
                }

                GroupBox(L("schedule.activeHours")) {
                    HStack {
                        Picker(L("schedule.from"), selection: $preferences.startHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .frame(maxWidth: 140)

                        Picker(L("schedule.to"), selection: $preferences.endHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .frame(maxWidth: 140)
                    }
                    .padding(4)
                }

                Text(L("schedule.helpText"))
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
