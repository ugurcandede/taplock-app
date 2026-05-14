import SwiftUI
import TapLockAppLib

struct TransparencyPickerRow: View {
    let label: String
    @Binding var selection: TransparencyPreset

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 0) {
                ForEach(TransparencyPreset.allCases) { preset in
                    Text(preset.label)
                        .font(.system(size: 10, weight: selection == preset ? .semibold : .regular, design: .monospaced))
                        .foregroundColor(selection == preset ? .accentColor : .secondary.opacity(0.5))
                        .frame(width: 28, height: 20)
                        .background(selection == preset ? Color.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                        .contentShape(Rectangle())
                        .onTapGesture { selection = preset }
                }
            }
        }
    }
}
