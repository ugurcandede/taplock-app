import Cocoa
import ServiceManagement
import SwiftUI
import TapLockCore

// MARK: - ViewModel

public final class MenuBarViewModel: ObservableObject {
    @Published public var isActive = false
    @Published public var isDelaying = false
    @Published public var delayRemaining: Int = 0
    @Published public var remainingSeconds: Int = 0
    @Published public var durationInput: String = ""
    @Published public var isInfiniteMode = true
    @Published public var delaySeconds: String = ""
    @Published public var dimEnabled = false
    @Published public var silentEnabled = false
    @Published public var keyboardOnly = false
    @Published public var showOverlay = true
    @Published public var showTimerInMenuBar = false
    @Published public var selectedColor: OverlayColor = .black
    @Published public var showSettings = false
    @Published public var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @Published public var sendUsageStats: Bool = Analytics.enabled { didSet { Analytics.enabled = sendUsageStats } }
    @Published public var lastError: String? = nil

    // Mode
    @Published public var currentMode: AppMode = .lock

    // Relax settings
    @Published public var relaxInterval: String = "25"
    @Published public var relaxIntervalUnit: DurationUnit = .minutes
    @Published public var relaxBreakDuration: String = "5"
    @Published public var relaxBreakUnit: DurationUnit = .minutes
    @Published public var relaxTheme: RelaxTheme = .breathing
    @Published public var relaxColor: OverlayColor = .green
    @Published public var relaxTransparency: TransparencyPreset = .light
    @Published public var relaxSilent: Bool = false
    @Published public var relaxShowTimerInMenuBar: Bool = false
    @Published public var relaxShowPostureReminder: Bool = true

    // Relax active state
    @Published public var isRelaxWaiting: Bool = false
    @Published public var isOnBreak: Bool = false
    @Published public var relaxRemainingSeconds: Int = 0

    // Stats — shared between the menubar dropdown and the Statistics window.
    @Published public var showStats: Bool = false
    @Published public var statsPeriod: StatsPeriodKind = .today
    @Published public var statsCustomStart: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published public var statsCustomEnd: Date = Date()
    @Published public var statsSummary: StatsSummary = .empty

    public var onSessionStateChanged: ((Bool) -> Void)?
    public var onLockStarted: (() -> Void)?
    public var onPopoverClose: (() -> Void)?
    public var onModeChanged: (() -> Void)?
    public var onOpenStatistics: (() -> Void)?
    private var session: TapLockSession?
    private var countdownTimer: Timer?
    private var delayTimer: Timer?
    private var relaxSession: RelaxingSession?
    private var relaxCountdownTimer: Timer?
    let maxSafetyDuration = 300
    let maxDuration = 3600 // 1 hour cap

    public init() {}

    public var parsedDuration: Int? {
        if isInfiniteMode { return nil }
        let trimmed = durationInput.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        return Int(trimmed).flatMap { $0 > 0 ? $0 : nil }
    }

    public func startSession() {
        guard !isActive else { return }
        lastError = nil
        Analytics.lastUsedMode = AppMode.lock.rawValue

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

    public func applyPreset(seconds: Int) {
        isInfiniteMode = false
        durationInput = "\(seconds)"
    }

    public func cancelSession() {
        if isDelaying {
            delayTimer?.invalidate()
            delayTimer = nil
            sessionEnded()
        } else {
            session?.cancel()
        }
    }

    public var hasAccessibility: Bool { InputBlocker.checkAccessibility() }

    public var formattedRemaining: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    public func filterDigits(_ value: inout String) {
        value = value.filter { $0.isNumber }
    }

    public func toggleLaunchAtLogin(_ enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func sessionEnded() {
        isActive = false
        isDelaying = false
        remainingSeconds = 0
        delayRemaining = 0
        countdownTimer?.invalidate()
        countdownTimer = nil
        delayTimer?.invalidate()
        delayTimer = nil
        session = nil
        loadStatsSummary()
        onSessionStateChanged?(false)
        onPopoverClose?()
    }

    // MARK: - Relax Session

    public func startRelaxSession() {
        guard !isActive && !isRelaxWaiting && !isOnBreak else { return }
        lastError = nil
        Analytics.lastUsedMode = AppMode.relax.rawValue

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
            silent: relaxSilent,
            showPostureReminder: relaxShowPostureReminder
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

    public func stopRelaxSession() {
        relaxSession?.cancel()
    }

    public func skipCurrentBreak() {
        relaxSession?.skipBreak()
    }

    func relaxSessionEnded() {
        isRelaxWaiting = false
        isOnBreak = false
        relaxRemainingSeconds = 0
        relaxCountdownTimer?.invalidate()
        relaxCountdownTimer = nil
        relaxSession = nil
        loadStatsSummary()
        onSessionStateChanged?(false)
        onPopoverClose?()
    }

    public func relaxBreakStarted() {
        guard let config = relaxSession?.config else { return }
        isOnBreak = true
        isRelaxWaiting = false
        relaxRemainingSeconds = config.breakDuration
        startRelaxCountdownTimer(seconds: config.breakDuration, isBreak: true)
        onSessionStateChanged?(true)
    }

    public func relaxBreakEnded() {
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

    public var formattedRelaxRemaining: String {
        let mins = relaxRemainingSeconds / 60
        let secs = relaxRemainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    public func applyRelaxPreset(interval: Int, breakDur: Int) {
        relaxInterval = "\(interval)"
        relaxIntervalUnit = .minutes
        relaxBreakDuration = "\(breakDur)"
        relaxBreakUnit = .minutes
    }

    /// Resolve the currently-selected period into a date interval.
    /// Returns nil for `.allTime`, meaning "no filter — include all events".
    public func currentStatsInterval(calendar: Calendar = .current) -> DateInterval? {
        let now = Date()
        switch statsPeriod {
        case .today:
            let start = calendar.startOfDay(for: now)
            return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: start) ?? now)
        case .yesterday:
            let todayStart = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? now
            return DateInterval(start: start, end: todayStart)
        case .thisWeek:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return nil }
            return weekInterval
        case .lastWeek:
            guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now),
                  let start = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek.start)
            else { return nil }
            return DateInterval(start: start, end: thisWeek.start)
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)
        case .lastMonth:
            guard let thisMonth = calendar.dateInterval(of: .month, for: now),
                  let start = calendar.date(byAdding: .month, value: -1, to: thisMonth.start)
            else { return nil }
            return DateInterval(start: start, end: thisMonth.start)
        case .thisYear:
            return calendar.dateInterval(of: .year, for: now)
        case .lastYear:
            guard let thisYear = calendar.dateInterval(of: .year, for: now),
                  let start = calendar.date(byAdding: .year, value: -1, to: thisYear.start)
            else { return nil }
            return DateInterval(start: start, end: thisYear.start)
        case .allTime:
            return nil
        case .custom:
            // Clamp end to start-of-next-day if user picked the same day, so DateInterval
            // is non-zero and event timestamps fall inside it.
            let start = calendar.startOfDay(for: statsCustomStart)
            let endDay = calendar.startOfDay(for: statsCustomEnd)
            let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? statsCustomEnd
            if end <= start { return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: start) ?? start) }
            return DateInterval(start: start, end: end)
        }
    }

    public func loadStatsSummary() {
        let store = StatsStore.shared
        let events: [StatsEvent]
        if let interval = currentStatsInterval() {
            events = store.events(in: interval)
        } else {
            events = store.allEvents()
        }
        statsSummary = StatsSummary.compute(from: events)
    }

    public func loadRelaxConfig() {
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
        relaxShowPostureReminder = config.showPostureReminder
    }

    // MARK: - Previews

    private var previewWindow: RelaxingWindowController?
    private var previewPosture: PostureWindowController?
    private var previewDismissTimer: Timer?

    public func previewTheme() {
        dismissPreview()
        let color = relaxColor.rgb
        previewWindow = RelaxingWindowController(
            duration: 99,
            theme: relaxTheme,
            color: (r: color.r, g: color.g, b: color.b),
            opacity: relaxTransparency.rawValue
        )
        previewWindow?.onSkip = { [weak self] in self?.dismissPreview() }
        previewWindow?.showOverlay()
        previewDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.dismissPreview()
        }
    }

    public func previewPostureReminder() {
        dismissPreview()
        previewPosture = PostureWindowController()
        previewPosture?.onDismiss = { [weak self] in self?.dismissPreview() }
        previewPosture?.showOverlay()
        previewDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.dismissPreview()
        }
    }

    private func dismissPreview() {
        previewDismissTimer?.invalidate()
        previewDismissTimer = nil
        previewWindow?.closeOverlay()
        previewWindow = nil
        previewPosture?.closeOverlay()
        previewPosture = nil
    }

    func bestUnit(seconds: Int) -> (Int, DurationUnit) {
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
