import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("0x")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.blue)
                .cornerRadius(16)

            Text("Blue Screen of Death")
                .font(.title2.bold())

            Text("A Modern Bell of Awareness")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("""
                Protect your eyesight and cultivate mindfulness. \
                Every few hours, a gentle blue screen reminder \
                encourages you to look away from the screen, \
                focus your eyes on something in the distance, \
                and take a mindful breath.

                Inspired by classic computing nostalgia, \
                reimagined as a tool for digital wellbeing.
                """)
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 380)
    }
}
