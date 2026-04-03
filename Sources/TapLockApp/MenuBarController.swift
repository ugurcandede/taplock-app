import Cocoa
import SwiftUI
import TapLockCore

// MARK: - Menu Bar Controller

final class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private let viewModel = MenuBarViewModel()
    private var menuBarTimer: Timer?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.behavior = .transient

        let hostingController = NSHostingController(
            rootView: MenuBarView(viewModel: viewModel)
        )
        hostingController.sizingOptions = .preferredContentSize
        popover.contentViewController = hostingController

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: "TapLock")
            button.action = #selector(togglePopover)
            button.target = self
        }

        viewModel.onSessionStateChanged = { [weak self] isActive in
            self?.updateStatusItem(isActive: isActive)
        }

        viewModel.onLockStarted = { [weak self] in
            self?.popover.performClose(nil)
        }

        viewModel.onPopoverClose = { [weak self] in
            self?.popover.performClose(nil)
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.contentViewController?.view.window?.makeFirstResponder(nil)
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeFirstResponder(nil)
        }
    }

    private func updateStatusItem(isActive: Bool) {
        let symbolName = isActive ? "lock.fill" : "lock.open.fill"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "TapLock"
        )

        menuBarTimer?.invalidate()
        menuBarTimer = nil

        if isActive && viewModel.showTimerInMenuBar {
            menuBarTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self, self.viewModel.isActive else {
                    timer.invalidate()
                    self?.statusItem.button?.title = ""
                    return
                }
                let mins = self.viewModel.remainingSeconds / 60
                let secs = self.viewModel.remainingSeconds % 60
                self.statusItem.button?.title = String(format: " %d:%02d", mins, secs)
            }
        } else {
            statusItem.button?.title = ""
        }
    }
}

// MARK: - ViewModel

final class MenuBarViewModel: ObservableObject {
    @Published var isActive = false
    @Published var isDelaying = false
    @Published var delayRemaining: Int = 0
    @Published var remainingSeconds: Int = 0
    @Published var durationInput: String = ""
    @Published var isInfiniteMode = true
    @Published var delaySeconds: String = ""
    @Published var dimEnabled = false
    @Published var silentEnabled = false
    @Published var keyboardOnly = false
    @Published var showOverlay = true
    @Published var showTimerInMenuBar = false
    @Published var selectedColor: OverlayColor = .defaultColor
    @Published var showSettings = false
    @Published var lastError: String? = nil

    var onSessionStateChanged: ((Bool) -> Void)?
    var onLockStarted: (() -> Void)?
    var onPopoverClose: (() -> Void)?
    private var session: TapLockSession?
    private var countdownTimer: Timer?
    private var delayTimer: Timer?
    private let maxSafetyDuration = 300
    private let maxDuration = 3600 // 1 hour cap

    var parsedDuration: Int? {
        if isInfiniteMode { return nil }
        let trimmed = durationInput.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        return Int(trimmed).flatMap { $0 > 0 ? $0 : nil }
    }

    func startSession() {
        guard !isActive else { return }
        lastError = nil

        guard InputBlocker.checkAccessibility() else {
            InputBlocker.requestAccessibility()
            lastError = "Accessibility permission required"
            return
        }

        let effectiveDuration = parsedDuration ?? maxSafetyDuration
        if effectiveDuration > maxDuration {
            lastError = "Maximum duration is \(maxDuration / 60) minutes"
            return
        }

        let delay = Int(delaySeconds) ?? 0

        if delay > 0 {
            isDelaying = true
            delayRemaining = delay
            isActive = true
            onSessionStateChanged?(true)

            delayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                self.delayRemaining -= 1
                if self.delayRemaining <= 0 {
                    timer.invalidate()
                    self.delayTimer = nil
                    self.isDelaying = false
                    self.beginLock(duration: effectiveDuration)
                }
            }
        } else {
            beginLock(duration: effectiveDuration)
        }
    }

    private func beginLock(duration: Int) {
        let config = SessionConfig(
            duration: duration,
            keyboardOnly: keyboardOnly,
            dim: dimEnabled,
            silent: silentEnabled,
            showOverlay: showOverlay,
            overlayColor: selectedColor.rgb
        )

        session = TapLockSession(config: config)
        session?.onEnd = { [weak self] in
            self?.sessionEnded()
        }

        do {
            try session?.start()
            isActive = true
            remainingSeconds = duration
            onSessionStateChanged?(true)
            onLockStarted?()
            startCountdownTimer()
        } catch {
            lastError = "\(error)"
            session = nil
            isActive = false
            onSessionStateChanged?(false)
        }
    }

    func applyPreset(seconds: Int) {
        isInfiniteMode = false
        durationInput = "\(seconds)"
    }

    func cancelSession() {
        if isDelaying {
            delayTimer?.invalidate()
            delayTimer = nil
            sessionEnded()
        } else {
            session?.cancel()
        }
    }

    var hasAccessibility: Bool { InputBlocker.checkAccessibility() }

    var formattedRemaining: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func filterDigits(_ value: inout String) {
        value = value.filter { $0.isNumber }
    }

    private func sessionEnded() {
        isActive = false
        isDelaying = false
        remainingSeconds = 0
        delayRemaining = 0
        countdownTimer?.invalidate()
        countdownTimer = nil
        delayTimer?.invalidate()
        delayTimer = nil
        session = nil
        onSessionStateChanged?(false)
        onPopoverClose?()
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                timer.invalidate()
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
        Group {
            if viewModel.isActive {
                ActiveView(viewModel: viewModel)
            } else {
                IdleView(viewModel: viewModel)
            }
        }
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut(duration: 0.15), value: viewModel.showSettings)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isInfiniteMode)
        .onAppear {
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onDisappear {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }
}

// MARK: - Active View

struct ActiveView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isDelaying {
                // Delay countdown
                VStack(spacing: 16) {
                    Text("\(viewModel.delayRemaining)")
                        .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                        .padding(.top, 24)

                    Text("starting in...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                // Lock countdown
                VStack(spacing: 16) {
                    Text(viewModel.formattedRemaining)
                        .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                        .padding(.top, 24)

                    Text(viewModel.keyboardOnly ? "keyboard blocked" : "all input blocked")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer().frame(height: 20)

            Button(action: { viewModel.cancelSession() }) {
                Text("cancel")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(8)
            .padding(.horizontal, 20)

            if !viewModel.isDelaying {
                Text("⌘⌥⌃L  hold 3s")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.top, 10)
            }

            Spacer().frame(height: 16)
        }
    }
}

// MARK: - Idle View

struct IdleView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @FocusState private var isDurationFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Accessibility warning
            if !viewModel.hasAccessibility {
                Button(action: { InputBlocker.requestAccessibility() }) {
                    HStack(spacing: 6) {
                        Circle().fill(.orange).frame(width: 6, height: 6)
                        Text("grant accessibility")
                            .font(.system(size: 11))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            .focusable(false)
                Divider().padding(.horizontal, 16)
            }

            // Error message
            if let error = viewModel.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 10))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }

            // Duration input area
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "infinity")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("indefinite")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.isInfiniteMode },
                        set: { val in
                            withAnimation { viewModel.isInfiniteMode = val }
                            if val { viewModel.durationInput = "" }
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if viewModel.isInfiniteMode {
                    Text("∞")
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.3))
                        .frame(height: 56)

                    Text("until cancelled  ·  safety: 5m")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                } else {
                    TextField("0", text: $viewModel.durationInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(height: 56)
                        .focused($isDurationFocused)
                        .padding(.horizontal, 20)
                        .onChange(of: viewModel.durationInput) { _ in
                            viewModel.filterDigits(&viewModel.durationInput)
                        }

                    Text("seconds")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }

                // Start button
                Button(action: { viewModel.startSession() }) {
                    Text("start")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
            .focusable(false)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
                .padding(.horizontal, 20)
            }

            // Preset buttons — fill input only, don't start
            HStack(spacing: 0) {
                PresetButton(label: "30s", seconds: 30, viewModel: viewModel)
                PresetButton(label: "1m", seconds: 60, viewModel: viewModel)
                PresetButton(label: "2m", seconds: 120, viewModel: viewModel)
                PresetButton(label: "5m", seconds: 300, viewModel: viewModel)
                PresetButton(label: "10m", seconds: 600, viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 12)

            // Settings
            Divider().padding(.horizontal, 16)

            Button(action: { withAnimation { viewModel.showSettings.toggle() } }) {
                HStack {
                    Text("settings")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.4))
                        .rotationEffect(.degrees(viewModel.showSettings ? 90 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)

            if viewModel.showSettings {
                Divider().padding(.horizontal, 16)
                SettingsSection(viewModel: viewModel)
                Divider().padding(.horizontal, 16)
                AboutSection()
            }

            Divider().padding(.horizontal, 16)

            Button(action: { NSApp.terminate(nil) }) {
                Text("quit taplock")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Settings

struct SettingsSection: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 8) {
            SettingToggle(label: "keyboard only", isOn: $viewModel.keyboardOnly)
            SettingToggle(label: "show overlay", isOn: $viewModel.showOverlay)
            SettingToggle(label: "dim screen", isOn: $viewModel.dimEnabled)
            SettingToggle(label: "silent", isOn: $viewModel.silentEnabled)
            SettingToggle(label: "show timer in menu bar", isOn: $viewModel.showTimerInMenuBar)

            HStack {
                Text("delay")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                TextField("0", text: $viewModel.delaySeconds)
                    .textFieldStyle(.plain)
                    .frame(width: 28)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(3)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(4)
                    .onChange(of: viewModel.delaySeconds) { _ in
                        viewModel.filterDigits(&viewModel.delaySeconds)
                    }
                Text("sec")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.4))
            }

            HStack {
                Text("color")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(OverlayColor.allCases) { color in
                        Button(action: { viewModel.selectedColor = color }) {
                            Circle()
                                .fill(color.preview)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle().stroke(
                                        viewModel.selectedColor == color
                                            ? Color.accentColor
                                            : Color.primary.opacity(0.1),
                                        lineWidth: viewModel.selectedColor == color ? 2 : 0.5
                                    )
                                )
                        }
                        .buttonStyle(.plain)
            .focusable(false)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - About

struct AboutSection: View {
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("Built with")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("❤️")
                    .font(.system(size: 9))
                Text("for")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("users")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
            }

            HStack(spacing: 5) {
                Link(destination: URL(string: "https://github.com/ugurcandede")!) {
                    Text("ugurcandede")
                        .font(.system(size: 10, weight: .medium))
                }

                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.3))

                Link(destination: URL(string: "https://github.com/ugurcandede/taplock")!) {
                    HStack(spacing: 3) {
                        Image(systemName: "tag")
                            .font(.system(size: 8))
                        Text("v0.1.0")
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Components

struct SettingToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
    }
}

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
