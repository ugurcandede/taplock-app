import AppKit
import SwiftUI
import TapLockAppLib
import TapLockCore

struct RelaxIdleView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Error message
            if let error = viewModel.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 10))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }

            // Duration input area
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("25", text: $viewModel.relaxInterval)
                        .textFieldStyle(.plain)
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: viewModel.relaxInterval) { _ in
                            viewModel.filterDigits(&viewModel.relaxInterval)
                        }
                    Text("/")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(.secondary.opacity(0.3))
                    TextField("5", text: $viewModel.relaxBreakDuration)
                        .textFieldStyle(.plain)
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .frame(width: 60)
                        .onChange(of: viewModel.relaxBreakDuration) { _ in
                            viewModel.filterDigits(&viewModel.relaxBreakDuration)
                        }
                }
                .frame(height: 56)
                .padding(.top, 12)

                // Unit selectors
                HStack(spacing: 16) {
                    UnitPicker(label: "every", selection: $viewModel.relaxIntervalUnit)
                    UnitPicker(label: "break", selection: $viewModel.relaxBreakUnit)
                }
                .padding(.horizontal, 20)

                // Start button
                Button(action: { viewModel.startRelaxSession() }) {
                    Text("start")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
                .padding(.horizontal, 20)
            }

            // Preset buttons
            HStack(spacing: 0) {
                RelaxPresetButton(label: "25/5", interval: 25, breakDur: 5, viewModel: viewModel)
                RelaxPresetButton(label: "45/10", interval: 45, breakDur: 10, viewModel: viewModel)
                RelaxPresetButton(label: "50/10", interval: 50, breakDur: 10, viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 12)

            // Stats (collapsible)
            Divider().padding(.horizontal, 16)
            StatsToggleRow(viewModel: viewModel)
            if viewModel.showStats {
                Divider().padding(.horizontal, 16)
                StatsDropdownSection(viewModel: viewModel, mode: .relax)
            }

            // Settings
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
                Divider().padding(.horizontal, 16)
                AboutSection()
            }

            Divider().padding(.horizontal, 16)

            Button(action: { NSApp.terminate(nil) }) {
                Text("quit taplock")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .padding(.bottom, 4)
        }
    }
}
