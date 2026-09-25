import SwiftUI
import TapLockAppLib
import TapLockCore

struct RelaxSettingsSection: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("theme")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { viewModel.previewTheme() }) {
                    Image(systemName: "eye")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Preview theme for 5 seconds")
                Picker("", selection: $viewModel.relaxTheme) {
                    ForEach(RelaxTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
            }

            ColorPickerRow(label: "color", selection: $viewModel.relaxColor, colors: OverlayColor.allCases)
            TransparencyPickerRow(label: "transparency", selection: $viewModel.relaxTransparency)
            HStack {
                Text("posture reminder")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { viewModel.previewPostureReminder() }) {
                    Image(systemName: "eye")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Preview posture reminder")
                Toggle("", isOn: $viewModel.relaxShowPostureReminder)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
            if viewModel.relaxShowPostureReminder {
                HStack {
                    Text("every")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("auto", text: $viewModel.relaxPostureInterval)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 44)
                        .onChange(of: viewModel.relaxPostureInterval) { _ in
                            viewModel.filterDigits(&viewModel.relaxPostureInterval)
                        }
                    Text("min")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 12)
            }

            Divider()

            SettingToggle(label: "launch at login", isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { viewModel.toggleLaunchAtLogin($0) }
            ))
            SettingToggle(label: "resume after restart", isOn: $viewModel.relaxResumeOnLaunch)
            SettingToggle(label: "silent", isOn: $viewModel.relaxSilent)
            SettingToggle(label: "show timer in menu bar", isOn: $viewModel.relaxShowTimerInMenuBar)
            SettingToggle(label: "send anonymous usage stats", isOn: $viewModel.sendUsageStats)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
