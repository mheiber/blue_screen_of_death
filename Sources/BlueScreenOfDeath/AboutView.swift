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
                .accessibilityLabel(L("about.title"))

            Text(L("about.title"))
                .font(.title2.bold())

            Text(L("about.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(L("about.description"))
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Text(L("about.versionFormat", "1.0.0"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 380)
    }
}
