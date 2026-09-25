import SwiftUI
import TapLockAppLib

struct UpdateBanner: View {
    let update: AppUpdate
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 11))
            Text(title)
                .font(.system(size: 11, weight: .medium))
            Spacer()
            switch viewModel.updateState {
            case .idle:
                if viewModel.canUpdate {
                    Button(action: { viewModel.performUpdate() }) {
                        Text("update")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help("Install v\(update.version) and relaunch")
                } else {
                    // Updating quits the app; not in the middle of a session.
                    Text("after session")
                        .font(.system(size: 11))
                        .opacity(0.6)
                }
            case .updating:
                ProgressView()
                    .controlSize(.mini)
            case .notInBrewYet:
                Button(action: { viewModel.performUpdate() }) {
                    Text("retry")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Homebrew gets new versions a few minutes after the release")
            case .failed:
                Button(action: { viewModel.openUpdateLog() }) {
                    Text("log")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Show what brew reported")
                Button(action: { viewModel.performUpdate() }) {
                    Text("retry")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            if viewModel.updateState != .updating {
                Button(action: { viewModel.dismissUpdate() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Hide until the next version")
            }
        }
        .foregroundColor(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(tint.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }

    private var tint: Color {
        viewModel.updateState == .failed ? .orange : .accentColor
    }

    private var title: String {
        switch viewModel.updateState {
        case .idle: return "v\(update.version) available"
        case .updating: return "updating to v\(update.version)…"
        case .notInBrewYet: return "not in Homebrew yet"
        case .failed: return "update failed"
        }
    }
}
