import Cocoa
import SwiftUI
import CleanLockCore

final class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private let viewModel = MenuBarViewModel()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(viewModel: viewModel)
        )

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: "CleanLock")
            button.action = #selector(togglePopover)
            button.target = self
        }

        viewModel.onSessionStateChanged = { [weak self] isActive in
            self?.updateIcon(isActive: isActive)
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func updateIcon(isActive: Bool) {
        let symbolName = isActive ? "lock.fill" : "lock.open.fill"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "CleanLock"
        )
    }
}

// MARK: - ViewModel

final class MenuBarViewModel: ObservableObject {
    @Published var isActive = false
    @Published var remainingSeconds: Int = 0
    @Published var dimEnabled = false
    @Published var silentEnabled = false

    var onSessionStateChanged: ((Bool) -> Void)?

    private var session: CleanLockSession?
    private var countdownTimer: Timer?

    func startSession(duration: Int) {
        guard !isActive else { return }
        guard InputBlocker.checkAccessibility() else {
            InputBlocker.requestAccessibility()
            return
        }

        let config = SessionConfig(
            duration: duration,
            dim: dimEnabled,
            silent: silentEnabled,
            showOverlay: true
        )

        session = CleanLockSession(config: config)
        session?.onEnd = { [weak self] in
            self?.sessionEnded()
        }

        do {
            try session?.start()
            isActive = true
            remainingSeconds = duration
            onSessionStateChanged?(true)
            startCountdownTimer()
        } catch {
            session = nil
        }
    }

    func cancelSession() {
        session?.cancel()
    }

    private func sessionEnded() {
        isActive = false
        remainingSeconds = 0
        countdownTimer?.invalidate()
        countdownTimer = nil
        session = nil
        onSessionStateChanged?(false)
    }

    private func startCountdownTimer() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            }
        }
    }

    var formattedRemaining: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        }
        return "\(secs)s"
    }
}

// MARK: - SwiftUI View

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isActive {
                activeView
            } else {
                inactiveView
            }
        }
        .padding()
        .frame(width: 260)
    }

    private var activeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)

            Text(viewModel.formattedRemaining)
                .font(.system(size: 40, weight: .light, design: .monospaced))

            Text("Input blocked")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Cancel") {
                viewModel.cancelSession()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private var inactiveView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 28))
                .foregroundColor(.secondary)

            Text("CleanLock")
                .font(.headline)

            // Duration buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                DurationButton(label: "30s", seconds: 30, viewModel: viewModel)
                DurationButton(label: "1m", seconds: 60, viewModel: viewModel)
                DurationButton(label: "2m", seconds: 120, viewModel: viewModel)
                DurationButton(label: "5m", seconds: 300, viewModel: viewModel)
            }

            Divider()

            // Settings
            Toggle("Dim screen", isOn: $viewModel.dimEnabled)
                .font(.caption)
            Toggle("Silent mode", isOn: $viewModel.silentEnabled)
                .font(.caption)

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

struct DurationButton: View {
    let label: String
    let seconds: Int
    let viewModel: MenuBarViewModel

    var body: some View {
        Button(label) {
            viewModel.startSession(duration: seconds)
        }
        .buttonStyle(.bordered)
    }
}
