import SwiftUI
import TapLockAppLib

struct PresetButton: View {
    let label: String
    let seconds: Int
    let viewModel: MenuBarViewModel

    var body: some View {
        Button(action: { viewModel.applyPreset(seconds: seconds) }) {
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
