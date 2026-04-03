import Cocoa
import SwiftUI
import TapLockCore

// MARK: - App Mode

enum AppMode: String, CaseIterable {
    case lock
    case relax
}

enum DurationUnit: String, CaseIterable {
    case seconds = "s"
    case minutes = "m"
    case hours = "h"

    var multiplier: Int {
        switch self {
        case .seconds: return 1
        case .minutes: return 60
        case .hours: return 3600
        }
    }
}

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

        viewModel.onModeChanged = { [weak self] in
            self?.updateStatusItem(isActive: false)
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
        let symbolName: String
        if viewModel.currentMode == .relax && (viewModel.isRelaxWaiting || viewModel.isOnBreak) {
            symbolName = "leaf.fill"
        } else if isActive {
            symbolName = "lock.fill"
        } else if viewModel.currentMode == .relax {
            symbolName = "leaf"
        } else {
            symbolName = "lock.open.fill"
        }
        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "TapLock"
        )

        menuBarTimer?.invalidate()
        menuBarTimer = nil

        let showTimer = viewModel.currentMode == .lock
            ? (isActive && viewModel.showTimerInMenuBar)
            : ((viewModel.isRelaxWaiting || viewModel.isOnBreak) && viewModel.relaxShowTimerInMenuBar)

        if showTimer {
            menuBarTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }

                let seconds: Int
                if self.viewModel.currentMode == .relax {
                    guard self.viewModel.isRelaxWaiting || self.viewModel.isOnBreak else {
                        timer.invalidate()
                        self.statusItem.button?.title = ""
                        return
                    }
                    seconds = self.viewModel.relaxRemainingSeconds
                } else {
                    guard self.viewModel.isActive else {
                        timer.invalidate()
                        self.statusItem.button?.title = ""
                        return
                    }
                    seconds = self.viewModel.remainingSeconds
                }

                let mins = seconds / 60
                let secs = seconds % 60
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
    @Published var selectedColor: OverlayColor = .black
    @Published var showSettings = false
    @Published var lastError: String? = nil

    // Mode
    @Published var currentMode: AppMode = .lock

    // Relax settings
    @Published var relaxInterval: String = "25"
    @Published var relaxIntervalUnit: DurationUnit = .minutes
    @Published var relaxBreakDuration: String = "5"
    @Published var relaxBreakUnit: DurationUnit = .minutes
    @Published var relaxTheme: RelaxTheme = .breathing
    @Published var relaxColor: OverlayColor = .green
    @Published var relaxTransparency: TransparencyPreset = .light
    @Published var relaxSilent: Bool = false
    @Published var relaxShowTimerInMenuBar: Bool = false

    // Relax active state
    @Published var isRelaxWaiting: Bool = false
    @Published var isOnBreak: Bool = false
    @Published var relaxRemainingSeconds: Int = 0

    var onSessionStateChanged: ((Bool) -> Void)?
    var onLockStarted: (() -> Void)?
    var onPopoverClose: (() -> Void)?
    var onModeChanged: (() -> Void)?
    private var session: TapLockSession?
    private var countdownTimer: Timer?
    private var delayTimer: Timer?
    private var relaxSession: RelaxingSession?
    private var relaxCountdownTimer: Timer?
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

    // MARK: - Relax Session

    func startRelaxSession() {
        guard !isActive && !isRelaxWaiting && !isOnBreak else { return }
        lastError = nil

        guard let intervalVal = Int(relaxInterval), intervalVal > 0 else {
            lastError = "Invalid interval"
            return
        }
        guard let breakVal = Int(relaxBreakDuration), breakVal > 0 else {
            lastError = "Invalid break duration"
            return
        }
        let intervalSec = intervalVal * relaxIntervalUnit.multiplier
        let breakSec = breakVal * relaxBreakUnit.multiplier
        if intervalSec <= breakSec {
            lastError = "Interval must be longer than break"
            return
        }

        let config = RelaxingSessionConfig(
            interval: intervalSec,
            breakDuration: breakSec,
            theme: relaxTheme,
            color: relaxColor.colorName,
            opacity: relaxTransparency.rawValue,
            silent: relaxSilent
        )

        // Save config
        try? ConfigStore.saveRelaxConfig(config)

        relaxSession = RelaxingSession(config: config)
        relaxSession?.onEnd = { [weak self] in
            self?.relaxSessionEnded()
        }
        relaxSession?.onBreakStart = { [weak self] in
            self?.relaxBreakStarted()
        }
        relaxSession?.onBreakEnd = { [weak self] in
            self?.relaxBreakEnded()
        }

        relaxRemainingSeconds = intervalSec
        isRelaxWaiting = true
        isOnBreak = false
        onSessionStateChanged?(true)
        onLockStarted?()

        relaxSession?.start()
        startRelaxCountdownTimer(seconds: intervalSec, isBreak: false)
    }

    func stopRelaxSession() {
        relaxSession?.cancel()
    }

    func skipCurrentBreak() {
        relaxSession?.skipBreak()
    }

    private func relaxSessionEnded() {
        isRelaxWaiting = false
        isOnBreak = false
        relaxRemainingSeconds = 0
        relaxCountdownTimer?.invalidate()
        relaxCountdownTimer = nil
        relaxSession = nil
        onSessionStateChanged?(false)
        onPopoverClose?()
    }

    func relaxBreakStarted() {
        guard let config = relaxSession?.config else { return }
        isOnBreak = true
        isRelaxWaiting = false
        relaxRemainingSeconds = config.breakDuration
        startRelaxCountdownTimer(seconds: config.breakDuration, isBreak: true)
        onSessionStateChanged?(true)
    }

    func relaxBreakEnded() {
        guard let config = relaxSession?.config else { return }
        isOnBreak = false
        isRelaxWaiting = true
        relaxRemainingSeconds = config.interval
        startRelaxCountdownTimer(seconds: config.interval, isBreak: false)
        onSessionStateChanged?(true)
    }

    private func startRelaxCountdownTimer(seconds: Int, isBreak: Bool) {
        relaxCountdownTimer?.invalidate()
        relaxRemainingSeconds = seconds
        relaxCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            if self.relaxRemainingSeconds > 0 {
                self.relaxRemainingSeconds -= 1
            } else {
                timer.invalidate()
            }
        }
    }

    var formattedRelaxRemaining: String {
        let mins = relaxRemainingSeconds / 60
        let secs = relaxRemainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func applyRelaxPreset(interval: Int, breakDur: Int) {
        relaxInterval = "\(interval)"
        relaxIntervalUnit = .minutes
        relaxBreakDuration = "\(breakDur)"
        relaxBreakUnit = .minutes
    }

    func loadRelaxConfig() {
        guard let config = ConfigStore.loadRelaxConfig() else { return }
        // Pick best unit for display
        let (iVal, iUnit) = bestUnit(seconds: config.interval)
        relaxInterval = "\(iVal)"
        relaxIntervalUnit = iUnit
        let (bVal, bUnit) = bestUnit(seconds: config.breakDuration)
        relaxBreakDuration = "\(bVal)"
        relaxBreakUnit = bUnit
        relaxTheme = config.theme
        relaxSilent = config.silent
        if let color = OverlayColor.fromColorName(config.color) {
            relaxColor = color
        }
    }

    private func bestUnit(seconds: Int) -> (Int, DurationUnit) {
        if seconds >= 3600 && seconds % 3600 == 0 { return (seconds / 3600, .hours) }
        if seconds >= 60 && seconds % 60 == 0 { return (seconds / 60, .minutes) }
        return (seconds, .seconds)
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
    case black = "Black"
    case white = "White"
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"

    var id: String { rawValue }

    var rgb: (r: Double, g: Double, b: Double) {
        switch self {
        case .black: return (0, 0, 0)
        case .white: return (1, 1, 1)
        case .red: return (1, 0, 0)
        case .blue: return (0, 0, 1)
        case .green: return (0, 0.8, 0)
        case .purple: return (0.5, 0, 0.5)
        }
    }

    var colorName: String {
        switch self {
        case .black: return "black"
        case .white: return "white"
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        case .purple: return "purple"
        }
    }

    static func fromColorName(_ name: String) -> OverlayColor? {
        allCases.first { $0.colorName == name }
    }

    var preview: Color {
        switch self {
        case .black: return .black
        case .white: return .white
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        }
    }
}

/// Transparency presets. Label shows transparency %, value is the actual opacity used.
/// 0% transparency = fully opaque, 100% = fully transparent.
enum TransparencyPreset: Double, CaseIterable, Identifiable {
    case none = 1.0
    case light = 0.85
    case medium = 0.50
    case high = 0.25
    case full = 0.10

    var id: Double { rawValue }

    var label: String {
        switch self {
        case .none: return "0"
        case .light: return "15"
        case .medium: return "50"
        case .high: return "75"
        case .full: return "90"
        }
    }
}

// MARK: - Main View

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    private var isAnySessionActive: Bool {
        viewModel.isActive || viewModel.isRelaxWaiting || viewModel.isOnBreak
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle (disabled when a session is active)
            if !isAnySessionActive {
                Picker("", selection: $viewModel.currentMode) {
                    Label("Lock", systemImage: "lock.fill").tag(AppMode.lock)
                    Label("Relax", systemImage: "leaf.fill").tag(AppMode.relax)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 4)
            }

            // Mode-specific content
            Group {
                switch viewModel.currentMode {
                case .lock:
                    if viewModel.isActive {
                        ActiveView(viewModel: viewModel)
                    } else {
                        IdleView(viewModel: viewModel)
                    }
                case .relax:
                    if viewModel.isRelaxWaiting || viewModel.isOnBreak {
                        RelaxActiveView(viewModel: viewModel)
                    } else {
                        RelaxIdleView(viewModel: viewModel)
                    }
                }
            }
        }
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut(duration: 0.15), value: viewModel.showSettings)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isInfiniteMode)
        .animation(.easeInOut(duration: 0.15), value: viewModel.currentMode)
        .onChange(of: viewModel.currentMode) { _ in
            viewModel.onModeChanged?()
        }
        .onAppear {
            viewModel.loadRelaxConfig()
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

            ColorPickerRow(label: "color", selection: $viewModel.selectedColor, colors: OverlayColor.allCases)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Relax Idle View

struct RelaxIdleView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
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
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("25", text: $viewModel.relaxInterval)
                        .textFieldStyle(.plain)
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: viewModel.relaxInterval) { _ in
                            viewModel.filterDigits(&viewModel.relaxInterval)
                        }
                    Text("/")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(.secondary.opacity(0.3))
                    TextField("5", text: $viewModel.relaxBreakDuration)
                        .textFieldStyle(.plain)
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .frame(width: 60)
                        .onChange(of: viewModel.relaxBreakDuration) { _ in
                            viewModel.filterDigits(&viewModel.relaxBreakDuration)
                        }
                }
                .frame(height: 56)
                .padding(.top, 12)

                // Unit selectors
                HStack(spacing: 16) {
                    UnitPicker(label: "every", selection: $viewModel.relaxIntervalUnit)
                    UnitPicker(label: "break", selection: $viewModel.relaxBreakUnit)
                }
                .padding(.horizontal, 20)

                // Start button
                Button(action: { viewModel.startRelaxSession() }) {
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

            // Preset buttons
            HStack(spacing: 0) {
                RelaxPresetButton(label: "25/5", interval: 25, breakDur: 5, viewModel: viewModel)
                RelaxPresetButton(label: "45/10", interval: 45, breakDur: 10, viewModel: viewModel)
                RelaxPresetButton(label: "50/10", interval: 50, breakDur: 10, viewModel: viewModel)
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
                RelaxSettingsSection(viewModel: viewModel)
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

// MARK: - Relax Settings

struct RelaxSettingsSection: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("theme")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: $viewModel.relaxTheme) {
                    ForEach(RelaxTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
            }

            ColorPickerRow(label: "color", selection: $viewModel.relaxColor, colors: OverlayColor.allCases)
            TransparencyPickerRow(label: "transparency", selection: $viewModel.relaxTransparency)

            SettingToggle(label: "silent", isOn: $viewModel.relaxSilent)
            SettingToggle(label: "show timer in menu bar", isOn: $viewModel.relaxShowTimerInMenuBar)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Relax Active View

struct RelaxActiveView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text(viewModel.formattedRelaxRemaining)
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .padding(.top, 24)

                Text(viewModel.isOnBreak ? "break time!" : "next break in...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 20)

            if viewModel.isOnBreak {
                Button(action: { viewModel.skipCurrentBreak() }) {
                    Text("skip")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(8)
                .padding(.horizontal, 20)

                Spacer().frame(height: 8)
            }

            Button(action: { viewModel.stopRelaxSession() }) {
                Text("stop")
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

            Spacer().frame(height: 16)
        }
    }
}

// MARK: - Relax Preset Button

struct RelaxPresetButton: View {
    let label: String
    let interval: Int
    let breakDur: Int
    let viewModel: MenuBarViewModel

    var body: some View {
        Button(action: { viewModel.applyRelaxPreset(interval: interval, breakDur: breakDur) }) {
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
                        Text(
                            "v\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ".dev")"
                        )
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
