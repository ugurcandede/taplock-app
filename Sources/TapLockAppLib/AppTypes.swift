import SwiftUI

// MARK: - App Mode

public enum AppMode: String, CaseIterable {
    case lock
    case relax
}

// MARK: - Duration Unit

public enum DurationUnit: String, CaseIterable {
    case seconds = "s"
    case minutes = "m"
    case hours = "h"

    public var multiplier: Int {
        switch self {
        case .seconds: return 1
        case .minutes: return 60
        case .hours: return 3600
        }
    }
}

// MARK: - Color Presets

public enum OverlayColor: String, CaseIterable, Identifiable {
    case black = "Black"
    case white = "White"
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"

    public var id: String { rawValue }

    public var rgb: (r: Double, g: Double, b: Double) {
        switch self {
        case .black: return (0, 0, 0)
        case .white: return (1, 1, 1)
        case .red: return (1, 0, 0)
        case .blue: return (0, 0, 1)
        case .green: return (0, 0.8, 0)
        case .purple: return (0.5, 0, 0.5)
        }
    }

    public var colorName: String {
        switch self {
        case .black: return "black"
        case .white: return "white"
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        case .purple: return "purple"
        }
    }

    public static func fromColorName(_ name: String) -> OverlayColor? {
        allCases.first { $0.colorName == name }
    }

    public var preview: Color {
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

// MARK: - Stats Period

public enum StatsPeriodKind: String, CaseIterable, Identifiable {
    case today
    case yesterday
    case thisWeek
    case lastWeek
    case thisMonth
    case lastMonth
    case thisYear
    case lastYear
    case allTime
    case custom

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case .thisWeek: return "this week"
        case .lastWeek: return "last week"
        case .thisMonth: return "this month"
        case .lastMonth: return "last month"
        case .thisYear: return "this year"
        case .lastYear: return "last year"
        case .allTime: return "all time"
        case .custom: return "custom"
        }
    }

    /// Periods exposed in the compact menubar picker. Detailed periods (yesterday,
    /// month/year ranges, all time, custom) live in the Statistics window only.
    public static var menubarOptions: [StatsPeriodKind] {
        [.today, .thisWeek, .lastWeek]
    }
}

/// Transparency presets. Label shows transparency %, value is the actual opacity used.
/// 0% transparency = fully opaque, 100% = fully transparent.
public enum TransparencyPreset: Double, CaseIterable, Identifiable {
    case none = 1.0
    case light = 0.85
    case medium = 0.50
    case high = 0.25
    case full = 0.10

    public var id: Double { rawValue }

    public var label: String {
        switch self {
        case .none: return "0"
        case .light: return "15"
        case .medium: return "50"
        case .high: return "75"
        case .full: return "90"
        }
    }
}
