import Testing
import TapLockCore
@testable import TapLockAppLib

// MARK: - AppMode

@Suite("AppMode")
struct AppModeTests {

    @Test func allCases() {
        #expect(AppMode.allCases == [.lock, .relax])
    }

    @Test func rawValues() {
        #expect(AppMode.lock.rawValue == "lock")
        #expect(AppMode.relax.rawValue == "relax")
    }
}

// MARK: - DurationUnit

@Suite("DurationUnit")
struct DurationUnitTests {

    @Test func multipliers() {
        #expect(DurationUnit.seconds.multiplier == 1)
        #expect(DurationUnit.minutes.multiplier == 60)
        #expect(DurationUnit.hours.multiplier == 3600)
    }

    @Test func allCasesCount() {
        #expect(DurationUnit.allCases.count == 3)
    }

    @Test func rawValues() {
        #expect(DurationUnit.seconds.rawValue == "s")
        #expect(DurationUnit.minutes.rawValue == "m")
        #expect(DurationUnit.hours.rawValue == "h")
    }

    @Test func durationCalculations() {
        #expect(25 * DurationUnit.minutes.multiplier == 1500)
        #expect(1 * DurationUnit.hours.multiplier == 3600)
        #expect(30 * DurationUnit.seconds.multiplier == 30)
    }
}

// MARK: - OverlayColor

@Suite("OverlayColor")
struct OverlayColorTests {

    @Test func allCasesCount() {
        #expect(OverlayColor.allCases.count == 6)
    }

    @Test func blackRGB() {
        let c = OverlayColor.black.rgb
        #expect(c.r == 0 && c.g == 0 && c.b == 0)
    }

    @Test func whiteRGB() {
        let c = OverlayColor.white.rgb
        #expect(c.r == 1 && c.g == 1 && c.b == 1)
    }

    @Test func redRGB() {
        let c = OverlayColor.red.rgb
        #expect(c.r == 1 && c.g == 0 && c.b == 0)
    }

    @Test func blueRGB() {
        let c = OverlayColor.blue.rgb
        #expect(c.r == 0 && c.g == 0 && c.b == 1)
    }

    @Test func greenRGB() {
        let c = OverlayColor.green.rgb
        #expect(c.r == 0 && c.g == 0.8 && c.b == 0)
    }

    @Test func purpleRGB() {
        let c = OverlayColor.purple.rgb
        #expect(c.r == 0.5 && c.g == 0 && c.b == 0.5)
    }

    @Test func colorNameReturnsLowercase() {
        for color in OverlayColor.allCases {
            #expect(color.colorName == color.colorName.lowercased())
        }
    }

    @Test func fromColorName_valid() {
        #expect(OverlayColor.fromColorName("red") == .red)
        #expect(OverlayColor.fromColorName("black") == .black)
        #expect(OverlayColor.fromColorName("green") == .green)
    }

    @Test func fromColorName_invalid() {
        #expect(OverlayColor.fromColorName("pink") == nil)
        #expect(OverlayColor.fromColorName("") == nil)
    }

    @Test func fromColorName_caseSensitive() {
        // fromColorName compares against lowercase colorName
        #expect(OverlayColor.fromColorName("Red") == nil)
        #expect(OverlayColor.fromColorName("BLACK") == nil)
    }

    @Test func identifiable() {
        for color in OverlayColor.allCases {
            #expect(color.id == color.rawValue)
        }
    }

    @Test func greenConsistentWithCoreParser() {
        let appGreen = OverlayColor.green.rgb
        let coreGreen = parseColor("green")
        #expect(coreGreen != nil)
        #expect(appGreen.r == coreGreen?.r)
        #expect(appGreen.g == coreGreen?.g)
        #expect(appGreen.b == coreGreen?.b)
    }

    @Test func allColorsConsistentWithCoreParser() {
        for color in OverlayColor.allCases {
            let appRGB = color.rgb
            let coreRGB = parseColor(color.colorName)
            #expect(coreRGB != nil, "\(color.colorName) should parse in TapLockCore")
            #expect(appRGB.r == coreRGB?.r, "\(color.colorName) red mismatch")
            #expect(appRGB.g == coreRGB?.g, "\(color.colorName) green mismatch")
            #expect(appRGB.b == coreRGB?.b, "\(color.colorName) blue mismatch")
        }
    }
}

// MARK: - TransparencyPreset

@Suite("TransparencyPreset")
struct TransparencyPresetTests {

    @Test func allCasesCount() {
        #expect(TransparencyPreset.allCases.count == 5)
    }

    @Test func rawValues() {
        #expect(TransparencyPreset.none.rawValue == 1.0)
        #expect(TransparencyPreset.light.rawValue == 0.85)
        #expect(TransparencyPreset.medium.rawValue == 0.50)
        #expect(TransparencyPreset.high.rawValue == 0.25)
        #expect(TransparencyPreset.full.rawValue == 0.10)
    }

    @Test func labels() {
        #expect(TransparencyPreset.none.label == "0")
        #expect(TransparencyPreset.light.label == "15")
        #expect(TransparencyPreset.medium.label == "50")
        #expect(TransparencyPreset.high.label == "75")
        #expect(TransparencyPreset.full.label == "90")
    }

    @Test func identifiable() {
        for preset in TransparencyPreset.allCases {
            #expect(preset.id == preset.rawValue)
        }
    }

    @Test func valuesDecreaseWithTransparency() {
        let values = TransparencyPreset.allCases.map(\.rawValue)
        for i in 0..<(values.count - 1) {
            #expect(values[i] > values[i + 1],
                    "Opacity should decrease as transparency increases")
        }
    }
}
