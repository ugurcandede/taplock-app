import SwiftUI
import TapLockAppLib

struct ColorPickerRow: View {
    let label: String
    @Binding var selection: OverlayColor
    let colors: [OverlayColor]

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(colors) { color in
                    Button(action: { selection = color }) {
                        Circle()
                            .fill(color.preview)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle().stroke(
                                    selection == color
                                        ? Color.accentColor
                                        : color == .black ? Color.secondary.opacity(0.5) : Color.primary.opacity(0.1),
                                    lineWidth: selection == color ? 2 : (color == .black ? 1 : 0.5)
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }
        }
    }
}
