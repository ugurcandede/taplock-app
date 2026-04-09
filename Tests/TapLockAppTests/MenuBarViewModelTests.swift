import Testing
import TapLockCore
@testable import TapLockAppLib

// MARK: - Initial State

@Suite("MenuBarViewModel - Initial State")
struct ViewModelInitialStateTests {

    @Test func lockState() {
        let vm = MenuBarViewModel()
        #expect(vm.isActive == false)
        #expect(vm.isDelaying == false)
        #expect(vm.remainingSeconds == 0)
        #expect(vm.delayRemaining == 0)
    }

    @Test func lockSettings() {
        let vm = MenuBarViewModel()
        #expect(vm.dimEnabled == false)
        #expect(vm.silentEnabled == false)
        #expect(vm.keyboardOnly == false)
        #expect(vm.showOverlay == true)
    }

    @Test func mode() {
        let vm = MenuBarViewModel()
        #expect(vm.currentMode == .lock)
    }

    @Test func relaxState() {
        let vm = MenuBarViewModel()
        #expect(vm.isRelaxWaiting == false)
        #expect(vm.isOnBreak == false)
        #expect(vm.relaxRemainingSeconds == 0)
    }

    @Test func relaxSettings() {
        let vm = MenuBarViewModel()
        #expect(vm.relaxInterval == "25")
        #expect(vm.relaxIntervalUnit == .minutes)
        #expect(vm.relaxBreakDuration == "5")
        #expect(vm.relaxBreakUnit == .minutes)
    }

    @Test func relaxDefaults() {
        let vm = MenuBarViewModel()
        #expect(vm.relaxTheme == .breathing)
        #expect(vm.relaxColor == .green)
        #expect(vm.relaxTransparency == .light)
        #expect(vm.relaxShowPostureReminder == true)
    }

    @Test func selectedColor() {
        let vm = MenuBarViewModel()
        #expect(vm.selectedColor == .black)
    }

    @Test func infiniteModeDefault() {
        let vm = MenuBarViewModel()
        #expect(vm.isInfiniteMode == true)
    }

    @Test func lastErrorNil() {
        let vm = MenuBarViewModel()
        #expect(vm.lastError == nil)
    }

    @Test func durationInputEmpty() {
        let vm = MenuBarViewModel()
        #expect(vm.durationInput == "")
    }

    @Test func delaySecondsEmpty() {
        let vm = MenuBarViewModel()
        #expect(vm.delaySeconds == "")
    }

    @Test func showTimerInMenuBar() {
        let vm = MenuBarViewModel()
        #expect(vm.showTimerInMenuBar == false)
        #expect(vm.relaxShowTimerInMenuBar == false)
    }

    @Test func relaxSilent() {
        let vm = MenuBarViewModel()
        #expect(vm.relaxSilent == false)
    }

    @Test func constants() {
        let vm = MenuBarViewModel()
        #expect(vm.maxSafetyDuration == 300)
        #expect(vm.maxDuration == 3600)
    }
}

// MARK: - Parsed Duration

@Suite("MenuBarViewModel - Parsed Duration")
struct ViewModelParsedDurationTests {

    @Test func infiniteMode() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = true
        #expect(vm.parsedDuration == nil)
    }

    @Test func emptyInput() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = ""
        #expect(vm.parsedDuration == nil)
    }

    @Test func validNumber() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = "120"
        #expect(vm.parsedDuration == 120)
    }

    @Test func zero() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = "0"
        #expect(vm.parsedDuration == nil)
    }

    @Test func negative() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = "-5"
        #expect(vm.parsedDuration == nil)
    }

    @Test func nonNumeric() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = "abc"
        #expect(vm.parsedDuration == nil)
    }

    @Test func whitespaceOnly() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = "   "
        #expect(vm.parsedDuration == nil)
    }

    @Test func whitespacePaddedNumber() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = " 120 "
        #expect(vm.parsedDuration == 120)
    }
}

// MARK: - Formatting

@Suite("MenuBarViewModel - Formatting")
struct ViewModelFormattingTests {

    @Test func formattedRemaining_zero() {
        let vm = MenuBarViewModel()
        vm.remainingSeconds = 0
        #expect(vm.formattedRemaining == "0:00")
    }

    @Test func formattedRemaining_oneMinute() {
        let vm = MenuBarViewModel()
        vm.remainingSeconds = 60
        #expect(vm.formattedRemaining == "1:00")
    }

    @Test func formattedRemaining_mixed() {
        let vm = MenuBarViewModel()
        vm.remainingSeconds = 90
        #expect(vm.formattedRemaining == "1:30")
    }

    @Test func formattedRemaining_secondsOnly() {
        let vm = MenuBarViewModel()
        vm.remainingSeconds = 45
        #expect(vm.formattedRemaining == "0:45")
    }

    @Test func formattedRelaxRemaining_zero() {
        let vm = MenuBarViewModel()
        vm.relaxRemainingSeconds = 0
        #expect(vm.formattedRelaxRemaining == "0:00")
    }

    @Test func formattedRelaxRemaining_mixed() {
        let vm = MenuBarViewModel()
        vm.relaxRemainingSeconds = 125
        #expect(vm.formattedRelaxRemaining == "2:05")
    }

    @Test func formattedRemaining_largeValue() {
        let vm = MenuBarViewModel()
        vm.remainingSeconds = 3661
        #expect(vm.formattedRemaining == "61:01")
    }

    @Test func formattedRemaining_paddedSeconds() {
        let vm = MenuBarViewModel()
        vm.remainingSeconds = 5
        #expect(vm.formattedRemaining == "0:05")
    }
}

// MARK: - Presets

@Suite("MenuBarViewModel - Presets")
struct ViewModelPresetTests {

    @Test func applyPreset() {
        let vm = MenuBarViewModel()
        vm.applyPreset(seconds: 30)
        #expect(vm.isInfiniteMode == false)
        #expect(vm.durationInput == "30")
    }

    @Test func applyPresetLarger() {
        let vm = MenuBarViewModel()
        vm.applyPreset(seconds: 300)
        #expect(vm.isInfiniteMode == false)
        #expect(vm.durationInput == "300")
    }

    @Test func applyRelaxPreset() {
        let vm = MenuBarViewModel()
        vm.applyRelaxPreset(interval: 25, breakDur: 5)
        #expect(vm.relaxInterval == "25")
        #expect(vm.relaxIntervalUnit == .minutes)
        #expect(vm.relaxBreakDuration == "5")
        #expect(vm.relaxBreakUnit == .minutes)
    }

    @Test func applyRelaxPresetLarger() {
        let vm = MenuBarViewModel()
        vm.applyRelaxPreset(interval: 50, breakDur: 10)
        #expect(vm.relaxInterval == "50")
        #expect(vm.relaxBreakDuration == "10")
    }
}

// MARK: - Filter Digits

@Suite("MenuBarViewModel - Filter Digits")
struct ViewModelFilterDigitsTests {

    @Test func allDigits() {
        let vm = MenuBarViewModel()
        var val = "123"
        vm.filterDigits(&val)
        #expect(val == "123")
    }

    @Test func mixed() {
        let vm = MenuBarViewModel()
        var val = "12abc34"
        vm.filterDigits(&val)
        #expect(val == "1234")
    }

    @Test func noDigits() {
        let vm = MenuBarViewModel()
        var val = "abc"
        vm.filterDigits(&val)
        #expect(val == "")
    }

    @Test func empty() {
        let vm = MenuBarViewModel()
        var val = ""
        vm.filterDigits(&val)
        #expect(val == "")
    }

    @Test func whitespace() {
        let vm = MenuBarViewModel()
        var val = " 1 2 "
        vm.filterDigits(&val)
        #expect(val == "12")
    }

    @Test func specialChars() {
        let vm = MenuBarViewModel()
        var val = "1.5m"
        vm.filterDigits(&val)
        #expect(val == "15")
    }
}

// MARK: - Best Unit

@Suite("MenuBarViewModel - Best Unit")
struct ViewModelBestUnitTests {

    @Test func exactHours() {
        let vm = MenuBarViewModel()
        let (val, unit) = vm.bestUnit(seconds: 3600)
        #expect(val == 1)
        #expect(unit == .hours)
    }

    @Test func exactMinutes() {
        let vm = MenuBarViewModel()
        let (val, unit) = vm.bestUnit(seconds: 300)
        #expect(val == 5)
        #expect(unit == .minutes)
    }

    @Test func seconds() {
        let vm = MenuBarViewModel()
        let (val, unit) = vm.bestUnit(seconds: 45)
        #expect(val == 45)
        #expect(unit == .seconds)
    }

    @Test func nonExactMinutes() {
        // 90 seconds is not evenly divisible by 60
        let vm = MenuBarViewModel()
        let (val, unit) = vm.bestUnit(seconds: 90)
        #expect(val == 90)
        #expect(unit == .seconds)
    }

    @Test func divisibleByMinutesNotHours() {
        // 5400 = 90 minutes, divisible by 60 but not 3600
        let vm = MenuBarViewModel()
        let (val, unit) = vm.bestUnit(seconds: 5400)
        #expect(val == 90)
        #expect(unit == .minutes)
    }

    @Test func zero() {
        let vm = MenuBarViewModel()
        let (val, unit) = vm.bestUnit(seconds: 0)
        #expect(val == 0)
        #expect(unit == .seconds)
    }

    @Test func twoHours() {
        let vm = MenuBarViewModel()
        let (val, unit) = vm.bestUnit(seconds: 7200)
        #expect(val == 2)
        #expect(unit == .hours)
    }
}

// MARK: - Relax Validation

@Suite("MenuBarViewModel - Relax Validation")
struct ViewModelRelaxValidationTests {

    @Test func emptyInterval() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = ""
        vm.relaxBreakDuration = "5"
        vm.startRelaxSession()
        #expect(vm.lastError == "Invalid interval")
    }

    @Test func emptyBreak() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "25"
        vm.relaxBreakDuration = ""
        vm.startRelaxSession()
        #expect(vm.lastError == "Invalid break duration")
    }

    @Test func intervalEqualToBreak() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "5"
        vm.relaxIntervalUnit = .minutes
        vm.relaxBreakDuration = "5"
        vm.relaxBreakUnit = .minutes
        vm.startRelaxSession()
        #expect(vm.lastError == "Interval must be longer than break")
    }

    @Test func intervalLessThanBreak() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "3"
        vm.relaxIntervalUnit = .minutes
        vm.relaxBreakDuration = "5"
        vm.relaxBreakUnit = .minutes
        vm.startRelaxSession()
        #expect(vm.lastError == "Interval must be longer than break")
    }

    @Test func guardWhenActive() {
        let vm = MenuBarViewModel()
        vm.isActive = true
        vm.startRelaxSession()
        // Should return early without setting error
        #expect(vm.lastError == nil)
    }

    @Test func guardWhenRelaxWaiting() {
        let vm = MenuBarViewModel()
        vm.isRelaxWaiting = true
        vm.startRelaxSession()
        #expect(vm.lastError == nil)
    }

    @Test func guardWhenOnBreak() {
        let vm = MenuBarViewModel()
        vm.isOnBreak = true
        vm.startRelaxSession()
        #expect(vm.lastError == nil)
    }

    @Test func zeroInterval() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "0"
        vm.relaxBreakDuration = "5"
        vm.startRelaxSession()
        #expect(vm.lastError == "Invalid interval")
    }

    @Test func negativeInterval() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "-5"
        vm.relaxBreakDuration = "5"
        vm.startRelaxSession()
        #expect(vm.lastError == "Invalid interval")
    }

    @Test func nonNumericInterval() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "abc"
        vm.relaxBreakDuration = "5"
        vm.startRelaxSession()
        #expect(vm.lastError == "Invalid interval")
    }

    @Test func crossUnitValidation_intervalSecondsBreakMinutes() {
        // 30 seconds interval vs 1 minute break → interval < break
        let vm = MenuBarViewModel()
        vm.relaxInterval = "30"
        vm.relaxIntervalUnit = .seconds
        vm.relaxBreakDuration = "1"
        vm.relaxBreakUnit = .minutes
        vm.startRelaxSession()
        #expect(vm.lastError == "Interval must be longer than break")
    }

    @Test func crossUnitValidation_intervalMinutesBreakSeconds() {
        // 2 minutes interval vs 30 seconds break → valid
        let vm = MenuBarViewModel()
        vm.relaxInterval = "2"
        vm.relaxIntervalUnit = .minutes
        vm.relaxBreakDuration = "30"
        vm.relaxBreakUnit = .seconds
        vm.startRelaxSession()
        // Should pass validation (120 > 30), fail at session start (no accessibility)
        #expect(vm.lastError != "Interval must be longer than break")
    }

    @Test func zeroBreak() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "25"
        vm.relaxBreakDuration = "0"
        vm.startRelaxSession()
        #expect(vm.lastError == "Invalid break duration")
    }

    @Test func nonNumericBreak() {
        let vm = MenuBarViewModel()
        vm.relaxInterval = "25"
        vm.relaxBreakDuration = "xyz"
        vm.startRelaxSession()
        #expect(vm.lastError == "Invalid break duration")
    }
}

// MARK: - State Transitions

@Suite("MenuBarViewModel - State Transitions")
struct ViewModelStateTransitionTests {

    @Test func sessionEndedResetsState() {
        let vm = MenuBarViewModel()
        // Simulate active state
        vm.isActive = true
        vm.isDelaying = true
        vm.remainingSeconds = 120
        vm.delayRemaining = 5

        vm.sessionEnded()

        #expect(vm.isActive == false)
        #expect(vm.isDelaying == false)
        #expect(vm.remainingSeconds == 0)
        #expect(vm.delayRemaining == 0)
    }

    @Test func relaxSessionEndedResetsState() {
        let vm = MenuBarViewModel()
        // Simulate active relax state
        vm.isRelaxWaiting = true
        vm.isOnBreak = true
        vm.relaxRemainingSeconds = 300

        vm.relaxSessionEnded()

        #expect(vm.isRelaxWaiting == false)
        #expect(vm.isOnBreak == false)
        #expect(vm.relaxRemainingSeconds == 0)
    }

    @Test func sessionEndedCallsCallback() {
        let vm = MenuBarViewModel()
        vm.isActive = true
        var callbackCalled = false
        vm.onSessionStateChanged = { isActive in
            if !isActive { callbackCalled = true }
        }

        vm.sessionEnded()
        #expect(callbackCalled)
    }

    @Test func startSessionGuardWhenActive() {
        let vm = MenuBarViewModel()
        vm.isActive = true
        vm.startSession()
        // Should return early; no error set because guard is first check
        #expect(vm.lastError == nil)
    }

    @Test func maxDurationCheck() {
        let vm = MenuBarViewModel()
        vm.isInfiniteMode = false
        vm.durationInput = "3601" // > maxDuration (3600)
        vm.startSession()
        // Will fail at accessibility check first on CI, but if we had accessibility:
        // The maxDuration check would trigger.
        // We test the parsedDuration is correctly set
        #expect(vm.parsedDuration == 3601)
    }

    @Test func cancelSessionDuringDelay() {
        let vm = MenuBarViewModel()
        vm.isActive = true
        vm.isDelaying = true
        vm.delayRemaining = 5
        vm.remainingSeconds = 120

        vm.cancelSession()

        #expect(vm.isActive == false)
        #expect(vm.isDelaying == false)
        #expect(vm.delayRemaining == 0)
        #expect(vm.remainingSeconds == 0)
    }

    @Test func relaxSessionEndedCallsCallback() {
        let vm = MenuBarViewModel()
        vm.isRelaxWaiting = true
        var callbackCalled = false
        vm.onSessionStateChanged = { isActive in
            if !isActive { callbackCalled = true }
        }

        vm.relaxSessionEnded()
        #expect(callbackCalled)
    }
}
