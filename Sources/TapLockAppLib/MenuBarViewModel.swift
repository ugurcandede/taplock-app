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
    @Published public var dimEnabled = false { didSet { trackSetting("lock_dim", dimEnabled) } }
    @Published public var silentEnabled = false { didSet { trackSetting("lock_silent", silentEnabled) } }
    @Published public var keyboardOnly = false { didSet { trackSetting("lock_keyboard_only", keyboardOnly) } }
    @Published public var showOverlay = true { didSet { trackSetting("lock_overlay", showOverlay) } }
    @Published public var showTimerInMenuBar = false { didSet { trackSetting("lock_menubar_timer", showTimerInMenuBar) } }
    @Published public var selectedColor: OverlayColor = .black { didSet { trackSetting("lock_color", selectedColor.colorName) } }
    @Published public var showSettings = false {
        didSet { if showSettings { Analytics.track("settings_opened", ["mode": currentMode.rawValue]) } }
    }
    @Published public var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @Published public var sendUsageStats: Bool = Analytics.enabled {
        didSet {
            Analytics.enabled = sendUsageStats
            trackSetting("usage_stats", sendUsageStats) // only lands when turned on
        }
    }
    @Published public var lastError: String? = nil

    // Mode
    @Published public var currentMode: AppMode = .lock {
        didSet { if currentMode != oldValue { Analytics.track("mode_changed", ["mode": currentMode.rawValue]) } }
    }

    // Relax settings
    @Published public var relaxInterval: String = "25"
    @Published public var relaxIntervalUnit: DurationUnit = .minutes
    @Published public var relaxBreakDuration: String = "5"
    @Published public var relaxBreakUnit: DurationUnit = .minutes
    // Appearance settings can change while a session runs; didSet pushes them into it.
    @Published public var relaxTheme: RelaxTheme = .breathing {
        didSet { updateActiveRelaxConfig(); trackSetting("relax_theme", relaxTheme.rawValue) }
    }
    @Published public var relaxColor: OverlayColor = .green {
        didSet { updateActiveRelaxConfig(); trackSetting("relax_color", relaxColor.colorName) }
    }
    @Published public var relaxTransparency: TransparencyPreset = .light {
        didSet { updateActiveRelaxConfig(); trackSetting("relax_transparency", relaxTransparency.label) }
    }
    @Published public var relaxSilent: Bool = false {
        didSet { updateActiveRelaxConfig(); trackSetting("relax_silent", relaxSilent) }
    }
    // The status item only redraws on session state changes, so nudge it here.
    @Published public var relaxShowTimerInMenuBar: Bool = false {
        didSet {
            if isRelaxWaiting || isOnBreak { onSessionStateChanged?(true) }
            trackSetting("relax_menubar_timer", relaxShowTimerInMenuBar)
        }
    }
    @Published public var relaxShowPostureReminder: Bool = true {
        didSet { updateActiveRelaxConfig(); trackSetting("relax_posture", relaxShowPostureReminder) }
    }
    /// Minutes between posture reminders; empty means once per interval (halfway).
    /// Not tracked per keystroke; relax_start carries the value in use.
    @Published public var relaxPostureInterval: String = "" { didSet { updateActiveRelaxConfig() } }
    @Published public var relaxResumeOnLaunch: Bool = UserDefaults.standard.bool(forKey: "relaxResumeOnLaunch") {
        didSet {
            UserDefaults.standard.set(relaxResumeOnLaunch, forKey: "relaxResumeOnLaunch")
            trackSetting("relax_resume_on_launch", relaxResumeOnLaunch)
        }
    }

    /// True while a relax session runs. Survives reboot/logout/crash so the session
    /// can resume on next launch; cleared when the session is stopped.
    static var relaxWasRunning: Bool {
        get { UserDefaults.standard.bool(forKey: "relaxWasRunning") }
        set { UserDefaults.standard.set(newValue, forKey: "relaxWasRunning") }
    }

    // Relax active state
    @Published public var isRelaxWaiting: Bool = false
    @Published public var isOnBreak: Bool = false
    @Published public var relaxRemainingSeconds: Int = 0

    // Stats — shared between the menubar dropdown and the Statistics window.
    @Published public var showStats: Bool = false {
        didSet { if showStats { Analytics.track("stats_opened", ["mode": currentMode.rawValue]) } }
    }
    @Published public var statsPeriod: StatsPeriodKind = .today {
        didSet { if statsPeriod != oldValue { Analytics.track("stats_period_changed", ["period": statsPeriod.rawValue]) } }
    }
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

    // Update banner
    @Published public var availableUpdate: AppUpdate?
    private var updateBannerTrackedVersion: String?

    // Analytics bookkeeping
    /// Set while config is loaded into the form, so those assignments are not
    /// reported as user setting changes.
    private var isLoadingSettings = false
    private var lockStartDate: Date?
    private var lockPlannedSeconds = 0
    private var lockEmergency = false
    private var relaxStartDate: Date?
    private var relaxBreaks = 0
    private var breakStartDate: Date?
    private var breakTrigger = "timer"
    private var isResuming = false
    private var emergencyObserver: NSObjectProtocol?

    public init() {
        emergencyObserver = NotificationCenter.default.addObserver(
            forName: .cleanLockEmergencyCancel, object: nil, queue: .main
        ) { [weak self] _ in
            self?.lockEmergency = true
        }
    }

    deinit {
        if let emergencyObserver { NotificationCenter.default.removeObserver(emergencyObserver) }
    }

    // MARK: - Analytics

    private func trackSetting(_ name: String, _ value: Any) {
        guard !isLoadingSettings else { return }
        Analytics.track("setting_changed", ["setting": name, "value": "\(value)"])
        refreshUserProperties()
    }

    /// Settings worth slicing every report by.
    public func refreshUserProperties() {
        Analytics.setUserProperties([
            "launch_at_login": launchAtLogin,
            "accessibility": hasAccessibility,
            "resume_on_launch": relaxResumeOnLaunch,
            "relax_theme": relaxTheme.rawValue,
        ])
    }

    /// Params for the periodic heartbeat while a session runs; nil when idle.
    public func heartbeatParams() -> [String: Any]? {
        if isActive { return ["mode": "lock", "state": isDelaying ? "delay" : "locked"] }
        if isRelaxWaiting || isOnBreak { return ["mode": "relax", "state": isOnBreak ? "break" : "waiting"] }
        return nil
    }

    public func popoverOpened() {
        let state = isActive || isRelaxWaiting || isOnBreak ? "active" : "idle"
        Analytics.track("popover_opened", ["mode": currentMode.rawValue, "state": state])
        if let update = availableUpdate, updateBannerTrackedVersion != update.version {
            updateBannerTrackedVersion = update.version
            Analytics.track("update_banner_shown", ["latest_version": update.version])
        }
    }

    public func accessibilityRequested() {
        Analytics.track("accessibility_requested")
        InputBlocker.requestAccessibility()
    }

    // MARK: - Updates

    public func checkForUpdates() {
        UpdateChecker.check { [weak self] update in
            self?.availableUpdate = update
        }
    }

    public func openUpdateNotes() {
        guard let update = availableUpdate else { return }
        Analytics.track("update_notes_opened", ["latest_version": update.version])
        NSWorkspace.shared.open(update.url)
    }

    public func copyBrewCommand() {
        guard let update = availableUpdate else { return }
        Analytics.track("update_brew_copied", ["latest_version": update.version])
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(UpdateChecker.brewCommand, forType: .string)
    }

    public func dismissUpdate() {
        guard let update = availableUpdate else { return }
        Analytics.track("update_dismissed", ["latest_version": update.version])
        UpdateChecker.dismissedVersion = update.version
        availableUpdate = nil
    }

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
            Analytics.track("lock_error", ["reason": "accessibility"])
            return
        }

        let effectiveDuration = parsedDuration ?? maxSafetyDuration
        if effectiveDuration > maxDuration {
            lastError = "Maximum duration is \(maxDuration / 60) minutes"
            Analytics.track("lock_error", ["reason": "too_long"])
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
            lockStartDate = Date()
            lockPlannedSeconds = duration
            lockEmergency = false
            Analytics.track("lock_start", [
                "duration_sec": duration,
                "indefinite": isInfiniteMode,
                "delay_sec": Int(delaySeconds) ?? 0,
                "keyboard_only": keyboardOnly,
                "dim": dimEnabled,
                "silent": silentEnabled,
                "overlay": showOverlay,
                "color": selectedColor.colorName,
                "menubar_timer": showTimerInMenuBar,
            ])
        } catch {
            Analytics.track("lock_error", ["reason": "start_failed"])
            lastError = "\(error)"
            session = nil
            isActive = false
            onSessionStateChanged?(false)
        }
    }

    public func applyPreset(seconds: Int) {
        Analytics.track("preset_applied", ["mode": "lock", "value": "\(seconds)s"])
        isInfiniteMode = false
        durationInput = "\(seconds)"
    }

    public func cancelSession() {
        if isDelaying {
            Analytics.track("lock_delay_cancelled")
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
        trackSetting("launch_at_login", launchAtLogin)
    }

    func sessionEnded() {
        if let start = lockStartDate {
            let actual = Int(Date().timeIntervalSince(start))
            let endedBy = lockEmergency ? "emergency" : (actual >= lockPlannedSeconds - 1 ? "completed" : "cancelled")
            Analytics.track("lock_end", [
                "planned_sec": lockPlannedSeconds,
                "actual_sec": actual,
                "ended_by": endedBy,
            ])
            lockStartDate = nil
        }
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
            Analytics.track("relax_error", ["reason": "invalid_interval"])
            return
        }
        guard let breakVal = Int(relaxBreakDuration), breakVal > 0 else {
            lastError = "Invalid break duration"
            Analytics.track("relax_error", ["reason": "invalid_break"])
            return
        }
        let intervalSec = intervalVal * relaxIntervalUnit.multiplier
        let breakSec = breakVal * relaxBreakUnit.multiplier
        if intervalSec <= breakSec {
            lastError = "Interval must be longer than break"
            Analytics.track("relax_error", ["reason": "interval_not_longer"])
            return
        }

        let config = RelaxingSessionConfig(
            interval: intervalSec,
            breakDuration: breakSec,
            theme: relaxTheme,
            color: relaxColor.colorName,
            opacity: relaxTransparency.rawValue,
            silent: relaxSilent,
            showPostureReminder: relaxShowPostureReminder,
            postureInterval: parsedPostureInterval
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
        Self.relaxWasRunning = true
        startRelaxCountdownTimer(seconds: intervalSec, isBreak: false)

        relaxStartDate = Date()
        relaxBreaks = 0
        Analytics.track("relax_start", [
            "interval_sec": intervalSec,
            "break_sec": breakSec,
            "theme": relaxTheme.rawValue,
            "color": relaxColor.colorName,
            "transparency": relaxTransparency.label,
            "silent": relaxSilent,
            "posture": relaxShowPostureReminder,
            "posture_interval_sec": parsedPostureInterval ?? 0,
            "menubar_timer": relaxShowTimerInMenuBar,
            "resumed": isResuming,
        ])
    }

    /// Restart the relax session from the saved config if it was running when the
    /// app last exited and the user opted in. Call once at launch.
    public func resumeRelaxSessionIfNeeded() {
        guard relaxResumeOnLaunch, Self.relaxWasRunning else { return }
        loadRelaxConfig()
        currentMode = .relax
        isResuming = true
        startRelaxSession()
        isResuming = false
    }

    public func stopRelaxSession() {
        relaxSession?.cancel()
    }

    public func skipCurrentBreak() {
        relaxSession?.skipBreak()
    }

    public func startBreakNow() {
        guard isRelaxWaiting else { return }
        breakTrigger = "manual"
        relaxSession?.startBreakNow()
    }

    /// Discard the running countdown and wait a full interval again.
    public func restartRelaxCountdown() {
        guard isRelaxWaiting, let session = relaxSession else { return }
        Analytics.track("relax_restart", ["elapsed_sec": session.config.interval - relaxRemainingSeconds])
        // skipBreak with no break showing just reschedules the next one.
        session.skipBreak()
        startRelaxCountdownTimer(seconds: session.config.interval, isBreak: false)
    }

    var parsedPostureInterval: Int? {
        Int(relaxPostureInterval).flatMap { $0 > 0 ? $0 * 60 : nil }
    }

    private func updateActiveRelaxConfig() {
        guard let session = relaxSession else { return }
        var config = session.config
        config.theme = relaxTheme
        config.color = relaxColor.colorName
        config.opacity = relaxTransparency.rawValue
        config.silent = relaxSilent
        config.showPostureReminder = relaxShowPostureReminder
        config.postureInterval = parsedPostureInterval
        session.config = config
        try? ConfigStore.saveRelaxConfig(config)
    }

    func relaxSessionEnded() {
        if let start = relaxStartDate {
            Analytics.track("relax_end", [
                "duration_sec": Int(Date().timeIntervalSince(start)),
                "breaks": relaxBreaks,
            ])
            relaxStartDate = nil
        }
        Self.relaxWasRunning = false
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
        breakStartDate = Date()
        Analytics.track("break_start", ["trigger": breakTrigger, "break_sec": config.breakDuration])
        breakTrigger = "timer"
        isOnBreak = true
        isRelaxWaiting = false
        relaxRemainingSeconds = config.breakDuration
        startRelaxCountdownTimer(seconds: config.breakDuration, isBreak: true)
        onSessionStateChanged?(true)
    }

    public func relaxBreakEnded() {
        guard let config = relaxSession?.config else { return }
        if let start = breakStartDate {
            let actual = Int(Date().timeIntervalSince(start))
            Analytics.track("break_end", [
                "planned_sec": config.breakDuration,
                "actual_sec": actual,
                "skipped": actual < config.breakDuration - 1,
            ])
            breakStartDate = nil
            relaxBreaks += 1
        }
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
        Analytics.track("preset_applied", ["mode": "relax", "value": "\(interval)/\(breakDur)"])
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
        isLoadingSettings = true
        defer { isLoadingSettings = false }
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
        if let transparency = TransparencyPreset(rawValue: config.opacity) {
            relaxTransparency = transparency
        }
        relaxShowPostureReminder = config.showPostureReminder
        relaxPostureInterval = config.postureInterval.map { "\($0 / 60)" } ?? ""
    }

    // MARK: - Previews

    private var previewWindow: RelaxingWindowController?
    private var previewPosture: PostureWindowController?
    private var previewDismissTimer: Timer?

    public func previewTheme() {
        Analytics.track("theme_previewed", ["theme": relaxTheme.rawValue])
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
        Analytics.track("posture_previewed")
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
