import SwiftUI
import TapLockAppLib

struct RelaxPresetButton: View {
    let label: String
    let interval: Int
    let breakDur: Int
    let viewModel: MenuBarViewModel

    var body: some View {
        Button(action: { viewModel.applyRelaxPreset(interval: interval, breakDur: breakDur) }) {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}
