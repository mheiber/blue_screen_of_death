import SwiftUI

// MARK: - Custom Interval View

struct CustomIntervalView: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var minutesText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Custom Interval")
                .font(.headline)

            HStack {
                Text("Minutes:")
                TextField("20", text: $minutesText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onAppear {
                        minutesText = "\(preferences.customMinutes)"
                    }
            }

            Text("Range: 1–240 minutes")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Apply") {
                if let mins = Int(minutesText), mins >= 1, mins <= 240 {
                    preferences.customMinutes = mins
                    preferences.useCustomInterval = true
                }
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .frame(width: 280)
    }
}
