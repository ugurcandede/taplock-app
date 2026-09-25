import SwiftUI
import TapLockAppLib

struct UpdateBanner: View {
    let update: AppUpdate
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 11))
            Text("v\(update.version) available")
                .font(.system(size: 11, weight: .medium))
            Spacer()
            Button(action: { viewModel.openUpdateNotes() }) {
                Text("notes")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open the release notes")
            Button(action: {
                viewModel.copyBrewCommand()
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
            }) {
                Text(copied ? "copied" : "copy brew")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help(UpdateChecker.brewCommand)
            Button(action: { viewModel.dismissUpdate() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Hide until the next version")
        }
        .foregroundColor(.accentColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }
}
