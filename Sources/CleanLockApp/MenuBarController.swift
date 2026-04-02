import Cocoa
import SwiftUI
import CleanLockCore

// MARK: - Menu Bar Controller

final class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private let viewModel = MenuBarViewModel()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 420)
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
    // Session state
    @Published var isActive = false
    @Published var remainingSeconds: Int = 0

    // Settings
    @Published var customMinutes: String = ""
    @Published var customSeconds: String = ""
    @Published var delaySeconds: String = ""
    @Published var dimEnabled = false
    @Published var silentEnabled = false
    @Published var keyboardOnly = false
    @Published var showOverlay = true
    @Published var selectedColor: OverlayColor = .defaultColor

    var onSessionStateChanged: ((Bool) -> Void)?

    private var session: CleanLockSession?
    private var countdownTimer: Timer?
    private let maxSafetyDuration = 300

    // MARK: - Actions

    func startSession(duration: Int?) {
        guard !isActive else { return }
        guard InputBlocker.checkAccessibility() else {
            InputBlocker.requestAccessibility()
            return
        }

        let effectiveDuration = duration ?? maxSafetyDuration

        // Apply delay if set
        let delay = Int(delaySeconds) ?? 0
        if delay > 0 {
            Thread.sleep(forTimeInterval: TimeInterval(delay))
        }

        let config = SessionConfig(
            duration: effectiveDuration,
            keyboardOnly: keyboardOnly,
            dim: dimEnabled,
            silent: silentEnabled,
            showOverlay: showOverlay,
            overlayColor: selectedColor.rgb
        )

        session = CleanLockSession(config: config)
        session?.onEnd = { [weak self] in
            self?.sessionEnded()
        }

        do {
            try session?.start()
            isActive = true
            remainingSeconds = effectiveDuration
            onSessionStateChanged?(true)
            startCountdownTimer()
        } catch {
            session = nil
        }
    }

    func startCustomSession() {
        let mins = Int(customMinutes) ?? 0
        let secs = Int(customSeconds) ?? 0
        let total = mins * 60 + secs
        guard total > 0 else { return }
        startSession(duration: total)
    }

    func cancelSession() {
        session?.cancel()
    }

    var hasAccessibility: Bool {
        InputBlocker.checkAccessibility()
    }

    var formattedRemaining: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Private

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
}

// MARK: - Color Presets

enum OverlayColor: String, CaseIterable, Identifiable {
    case defaultColor = "Default"
    case black = "Black"
    case white = "White"
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"

    var id: String { rawValue }

    var rgb: (r: Double, g: Double, b: Double)? {
        switch self {
        case .defaultColor: return nil
        case .black: return (0, 0, 0)
        case .white: return (1, 1, 1)
        case .red: return (1, 0, 0)
        case .blue: return (0, 0, 1)
        case .green: return (0, 0.8, 0)
        case .purple: return (0.5, 0, 0.5)
        }
    }

    var preview: Color {
        switch self {
        case .defaultColor: return Color.black.opacity(0.85)
        case .black: return .black
        case .white: return .white
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        }
    }
}

// MARK: - Main View

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isActive {
                ActiveSessionView(viewModel: viewModel)
            } else {
                IdleView(viewModel: viewModel)
            }
        }
        .frame(width: 300)
    }
}

// MARK: - Active Session View

struct ActiveSessionView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 8)

            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)

            Text(viewModel.formattedRemaining)
                .font(.system(size: 48, weight: .ultraLight, design: .monospaced))

            HStack(spacing: 16) {
                if viewModel.keyboardOnly {
                    Label("Keyboard", systemImage: "keyboard")
                } else {
                    Label("All input", systemImage: "keyboard")
                }
                if viewModel.dimEnabled {
                    Label("Dimmed", systemImage: "sun.min")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Button(action: { viewModel.cancelSession() }) {
                Text("Cancel Lock")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .padding(.horizontal)

            Text("or hold ⌘⌥⌃L for 3 seconds")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer().frame(height: 8)
        }
        .padding()
    }
}

// MARK: - Idle View

struct IdleView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "lock.open.fill")
                    .foregroundColor(.secondary)
                Text("CleanLock")
                    .font(.headline)
                Spacer()
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Accessibility warning
            if !viewModel.hasAccessibility {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Accessibility permission required")
                        .font(.caption)
                    Spacer()
                    Button("Grant") {
                        InputBlocker.requestAccessibility()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            // Quick durations
            VStack(spacing: 8) {
                Text("Quick Start")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    QuickButton(label: "30s", seconds: 30, viewModel: viewModel)
                    QuickButton(label: "1m", seconds: 60, viewModel: viewModel)
                    QuickButton(label: "2m", seconds: 120, viewModel: viewModel)
                    QuickButton(label: "5m", seconds: 300, viewModel: viewModel)
                    QuickButton(label: "10m", seconds: 600, viewModel: viewModel)
                    QuickButton(label: "∞", seconds: nil, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            // Custom duration
            VStack(spacing: 8) {
                Text("Custom Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        TextField("0", text: $viewModel.customMinutes)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 44)
                            .multilineTextAlignment(.center)
                        Text("min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        TextField("0", text: $viewModel.customSeconds)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 44)
                            .multilineTextAlignment(.center)
                        Text("sec")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button("Start") {
                        viewModel.startCustomSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            // Settings (collapsible)
            if showSettings {
                Divider()
                SettingsSection(viewModel: viewModel)
            }

            Divider()

            // Footer
            Button("Quit CleanLock") {
                NSApp.terminate(nil)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Settings Section

struct SettingsSection: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Toggles
            VStack(spacing: 6) {
                Toggle("Keyboard only (don't block trackpad)", isOn: $viewModel.keyboardOnly)
                Toggle("Show overlay", isOn: $viewModel.showOverlay)
                Toggle("Dim screen", isOn: $viewModel.dimEnabled)
                Toggle("Silent mode", isOn: $viewModel.silentEnabled)
            }
            .font(.caption)

            // Delay
            HStack {
                Text("Delay before lock:")
                    .font(.caption)
                Spacer()
                TextField("0", text: $viewModel.delaySeconds)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 40)
                    .multilineTextAlignment(.center)
                Text("sec")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Overlay color
            HStack {
                Text("Overlay color:")
                    .font(.caption)
                Spacer()
                Picker("", selection: $viewModel.selectedColor) {
                    ForEach(OverlayColor.allCases) { color in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(color.preview)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                            Text(color.rawValue)
                        }
                        .tag(color)
                    }
                }
                .frame(width: 120)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Quick Button

struct QuickButton: View {
    let label: String
    let seconds: Int?
    let viewModel: MenuBarViewModel

    var body: some View {
        Button(action: { viewModel.startSession(duration: seconds) }) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 32)
        }
        .buttonStyle(.bordered)
    }
}
