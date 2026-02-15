import SwiftUI

// MARK: - Custom Interval View

struct CustomIntervalView: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var minutesText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(L("customInterval.title"))
                .font(.headline)

            HStack {
                Text(L("customInterval.minutes"))
                TextField("20", text: $minutesText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onAppear {
                        minutesText = "\(preferences.customMinutes)"
                    }
                    .accessibilityLabel(L("customInterval.minutes"))
            }

            Text(L("customInterval.range"))
                .font(.caption)
                .foregroundColor(.secondary)

            Button(L("customInterval.apply")) {
                if let mins = Int(minutesText), mins >= 1, mins <= 240 {
                    preferences.customMinutes = mins
                    preferences.useCustomInterval = true
                }
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityHint(L("customInterval.range"))
        }
        .padding(20)
        .frame(width: 280)
    }
}
