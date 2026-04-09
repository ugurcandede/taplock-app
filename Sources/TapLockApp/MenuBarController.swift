import Cocoa
import ServiceManagement
import SwiftUI
import TapLockAppLib
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
            SettingToggle(label: "launch at login", isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { viewModel.toggleLaunchAtLogin($0) }
            ))
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
                Button(action: { viewModel.previewTheme() }) {
                    Image(systemName: "eye")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Preview theme for 5 seconds")
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

            SettingToggle(label: "launch at login", isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { viewModel.toggleLaunchAtLogin($0) }
            ))
            SettingToggle(label: "silent", isOn: $viewModel.relaxSilent)
            SettingToggle(label: "show timer in menu bar", isOn: $viewModel.relaxShowTimerInMenuBar)
            HStack {
                Text("posture reminder")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { viewModel.previewPostureReminder() }) {
                    Image(systemName: "eye")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Preview posture reminder")
                Toggle("", isOn: $viewModel.relaxShowPostureReminder)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
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
