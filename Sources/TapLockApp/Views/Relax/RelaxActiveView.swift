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
            } else {
                HStack(spacing: 8) {
                    Button(action: { viewModel.startBreakNow() }) {
                        Text("break now")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(8)

                    Button(action: { viewModel.restartRelaxCountdown() }) {
                        Text("restart")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }
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

            // Appearance settings apply from the next break; interval/break need a restart.
            Divider().padding(.horizontal, 16)

            Button(action: { withAnimation { viewModel.showSettings.toggle() } }) {
                HStack {
                    Text("settings")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.4))
                        .rotationEffect(.degrees(viewModel.showSettings ? 90 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)

            if viewModel.showSettings {
                Divider().padding(.horizontal, 16)
                RelaxSettingsSection(viewModel: viewModel)
            }
        }
    }
}
