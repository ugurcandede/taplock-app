import SwiftUI
import TapLockAppLib

struct ActiveView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isDelaying {
                // Delay countdown
                VStack(spacing: 16) {
                    Text("\(viewModel.delayRemaining)")
                        .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                        .padding(.top, 24)

                    Text("starting in...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                // Lock countdown
                VStack(spacing: 16) {
                    Text(viewModel.formattedRemaining)
                        .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                        .padding(.top, 24)

                    Text(viewModel.keyboardOnly ? "keyboard blocked" : "all input blocked")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer().frame(height: 20)

            Button(action: { viewModel.cancelSession() }) {
                Text("cancel")
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

            if !viewModel.isDelaying {
                Text("⌘⌥⌃L  hold 3s")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.top, 10)
            }

            Spacer().frame(height: 16)
        }
    }
}
