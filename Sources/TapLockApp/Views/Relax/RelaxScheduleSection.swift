import SwiftUI
import TapLockAppLib

/// Advanced relax schedule, shown in the idle view when the advanced toggle is on.
/// Collapsed to a one-line summary; tap it to edit.
struct RelaxScheduleSection: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var isEditing = false
    /// Label of the row whose explanation is open. Tooltips (.help) don't show in a
    /// menu bar popover, so explanations open inline on tap instead.
    @State private var openInfo: String?

    /// Monday-first display order of Calendar weekday numbers.
    private let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]

    private static let hoursInfo = "Breaks only happen between these times. Outside them the timer waits, and starts counting again when they begin."
    private static let quietInfo = "No breaks in this window, e.g. lunch. The timer starts counting again when it ends."
    private static let fixedInfo = "Breaks land on the same clock times every day, counted from the start of your hours (50/10 → 9:50, 10:50, 11:50), instead of from when you press start."

    var body: some View {
        VStack(spacing: 8) {
            summaryRow

            if isEditing {
                HStack(spacing: 4) {
                    ForEach(weekdayOrder, id: \.self) { day in
                        dayChip(day)
                    }
                }

                HStack(spacing: 4) {
                    label("hours")
                    Spacer()
                    timePicker($viewModel.relaxActiveStart)
                    Text("–").foregroundColor(.secondary)
                    timePicker($viewModel.relaxActiveEnd, isEnd: true)
                }
                infoText("hours", Self.hoursInfo)

                toggleRow("quiet hours", isOn: $viewModel.relaxQuietEnabled)
                infoText("quiet hours", Self.quietInfo)
                if viewModel.relaxQuietEnabled {
                    HStack(spacing: 4) {
                        Spacer()
                        timePicker($viewModel.relaxQuietStart)
                        Text("–").foregroundColor(.secondary)
                        timePicker($viewModel.relaxQuietEnd, isEnd: true)
                    }
                }

                toggleRow("fixed break times", isOn: $viewModel.relaxAlignToClock)
                infoText("fixed break times", Self.fixedInfo)
            }

            preview
        }
        .padding(.vertical, 4)
    }

    // MARK: - Summary

    private var summaryRow: some View {
        Button(action: { withAnimation { isEditing.toggle() } }) {
            HStack {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.4))
                    .rotationEffect(.degrees(isEditing ? 90 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    /// e.g. "weekdays · 9:00 AM–6:00 PM · quiet · fixed"
    private var summary: String {
        var parts = [daysText, "\(clock(viewModel.relaxActiveStart))–\(clock(viewModel.relaxActiveEnd))"]
        if viewModel.relaxQuietEnabled { parts.append("quiet") }
        if viewModel.relaxAlignToClock { parts.append("fixed") }
        return parts.joined(separator: " · ")
    }

    private var daysText: String {
        let days = viewModel.relaxWeekdays
        switch days {
        case Set(1...7): return "every day"
        case [2, 3, 4, 5, 6]: return "weekdays"
        case [1, 7]: return "weekends"
        case []: return "no days"
        default:
            let symbols = Calendar.current.shortWeekdaySymbols
            return weekdayOrder.filter(days.contains).map { symbols[$0 - 1] }.joined(separator: " ")
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var preview: some View {
        if let error = viewModel.scheduleError {
            Text(error.lowercased())
                .font(.system(size: 10))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let dates = viewModel.schedulePreview {
            Text(dates.isEmpty ? "no breaks with these settings" : "breaks: " + dates.map(format).joined(separator: " · ") + " …")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(dates.isEmpty ? .red : .secondary.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate(Calendar.current.isDateInToday(date) ? "jmm" : "EEEjmm")
        return f.string(from: date)
    }

    private func clock(_ minutes: Int) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("jmm")
        return f.string(from: Self.today(at: minutes))
    }

    /// Today at `minutes` past midnight, by clock time so DST days don't shift it.
    private static func today(at minutes: Int) -> Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: Date())
        guard minutes < 24 * 60 else { return cal.date(byAdding: .day, value: 1, to: day) ?? day }
        return cal.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day) ?? day
    }

    // MARK: - Rows

    private func label(_ text: String) -> some View {
        Button(action: { withAnimation { openInfo = openInfo == text ? nil : text } }) {
            HStack(spacing: 3) {
                Text(text)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Image(systemName: openInfo == text ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    @ViewBuilder
    private func infoText(_ key: String, _ text: String) -> some View {
        if openInfo == key {
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func toggleRow(_ text: String, isOn: Binding<Bool>) -> some View {
        HStack {
            label(text)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
    }

    private func dayChip(_ day: Int) -> some View {
        let selected = viewModel.relaxWeekdays.contains(day)
        return Button(action: {
            if selected { viewModel.relaxWeekdays.remove(day) } else { viewModel.relaxWeekdays.insert(day) }
        }) {
            Text(Calendar.current.veryShortWeekdaySymbols[day - 1])
                .font(.system(size: 10, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 20)
                .background(selected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                .foregroundColor(selected ? .accentColor : .secondary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    /// An end picked as 00:00 means midnight at the end of the day (24:00).
    private func timePicker(_ minutes: Binding<Int>, isEnd: Bool = false) -> some View {
        let date = Binding<Date>(
            get: { Self.today(at: minutes.wrappedValue) },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                let value = (c.hour ?? 0) * 60 + (c.minute ?? 0)
                minutes.wrappedValue = isEnd && value == 0 ? 24 * 60 : value
            }
        )
        return DatePicker("", selection: date, displayedComponents: .hourAndMinute)
            .labelsHidden()
            .datePickerStyle(.field)
            .font(.system(size: 11))
    }
}
