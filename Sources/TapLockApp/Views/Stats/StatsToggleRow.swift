import SwiftUI
import TapLockAppLib

struct StatsToggleRow: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        Button(action: { withAnimation { viewModel.showStats.toggle() } }) {
            HStack {
                Text("stats")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.4))
                    .rotationEffect(.degrees(viewModel.showStats ? 90 : 0))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}
