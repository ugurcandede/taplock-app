import AppKit
import SwiftUI
import TapLockAppLib
import TapLockCore

struct IdleView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @FocusState private var isDurationFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Accessibility warning
            if !viewModel.hasAccessibility {
                Button(action: { InputBlocker.requestAccessibility() }) {
                    HStack(spacing: 6) {
                        Circle().fill(.orange).frame(width: 6, height: 6)
                        Text("grant accessibility")
                            .font(.system(size: 11))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            .focusable(false)
                Divider().padding(.horizontal, 16)
            }

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
                HStack {
                    Image(systemName: "infinity")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("indefinite")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.isInfiniteMode },
                        set: { val in
                            withAnimation { viewModel.isInfiniteMode = val }
                            if val { viewModel.durationInput = "" }
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if viewModel.isInfiniteMode {
                    Text("∞")
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.3))
                        .frame(height: 56)

                    Text("until cancelled  ·  safety: 5m")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                } else {
                    TextField("0", text: $viewModel.durationInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(height: 56)
                        .focused($isDurationFocused)
                        .padding(.horizontal, 20)
                        .onChange(of: viewModel.durationInput) { _ in
                            viewModel.filterDigits(&viewModel.durationInput)
                        }

                    Text("seconds")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }

                // Start button
                Button(action: { viewModel.startSession() }) {
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

            // Preset buttons — fill input only, don't start
            HStack(spacing: 0) {
                PresetButton(label: "30s", seconds: 30, viewModel: viewModel)
                PresetButton(label: "1m", seconds: 60, viewModel: viewModel)
                PresetButton(label: "2m", seconds: 120, viewModel: viewModel)
                PresetButton(label: "5m", seconds: 300, viewModel: viewModel)
                PresetButton(label: "10m", seconds: 600, viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 12)

            // Stats (collapsible)
            Divider().padding(.horizontal, 16)
            StatsToggleRow(viewModel: viewModel)
            if viewModel.showStats {
                Divider().padding(.horizontal, 16)
                StatsDropdownSection(viewModel: viewModel, mode: .lock)
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
                SettingsSection(viewModel: viewModel)
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
