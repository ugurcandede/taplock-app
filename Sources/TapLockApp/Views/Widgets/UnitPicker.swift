import SwiftUI
import TapLockAppLib

struct UnitPicker: View {
    let label: String
    @Binding var selection: DurationUnit

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))
            HStack(spacing: 0) {
                ForEach(DurationUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue)
                        .font(.system(size: 11, weight: selection == unit ? .semibold : .regular, design: .monospaced))
                        .foregroundColor(selection == unit ? .accentColor : .secondary.opacity(0.5))
                        .frame(width: 28, height: 22)
                        .background(selection == unit ? Color.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                        .contentShape(Rectangle())
                        .onTapGesture { selection = unit }
                }
            }
        }
    }
}
