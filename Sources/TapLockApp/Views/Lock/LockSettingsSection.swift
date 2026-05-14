import SwiftUI
import TapLockAppLib

struct SettingsSection: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 8) {
            SettingToggle(label: "launch at login", isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { viewModel.toggleLaunchAtLogin($0) }
            ))
            SettingToggle(label: "keyboard only", isOn: $viewModel.keyboardOnly)
            SettingToggle(label: "show overlay", isOn: $viewModel.showOverlay)
            SettingToggle(label: "dim screen", isOn: $viewModel.dimEnabled)
            SettingToggle(label: "silent", isOn: $viewModel.silentEnabled)
            SettingToggle(label: "show timer in menu bar", isOn: $viewModel.showTimerInMenuBar)

            HStack {
                Text("delay")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                TextField("0", text: $viewModel.delaySeconds)
                    .textFieldStyle(.plain)
                    .frame(width: 28)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(3)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(4)
                    .onChange(of: viewModel.delaySeconds) { _ in
                        viewModel.filterDigits(&viewModel.delaySeconds)
                    }
                Text("sec")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.4))
            }

            ColorPickerRow(label: "color", selection: $viewModel.selectedColor, colors: OverlayColor.allCases)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
