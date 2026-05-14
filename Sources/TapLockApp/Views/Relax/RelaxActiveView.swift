import SwiftUI
import TapLockAppLib

struct RelaxActiveView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text(viewModel.formattedRelaxRemaining)
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .padding(.top, 24)

                Text(viewModel.isOnBreak ? "break time!" : "next break in...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 20)

            if viewModel.isOnBreak {
                Button(action: { viewModel.skipCurrentBreak() }) {
                    Text("skip")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(8)
                .padding(.horizontal, 20)

                Spacer().frame(height: 8)
            }

            Button(action: { viewModel.stopRelaxSession() }) {
                Text("stop")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(8)
            .padding(.horizontal, 20)

            Spacer().frame(height: 16)
        }
    }
}
