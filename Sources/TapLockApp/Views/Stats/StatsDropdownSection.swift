import SwiftUI
import TapLockAppLib
import TapLockCore

struct StatsDropdownSection: View {
    @ObservedObject var viewModel: MenuBarViewModel
    let mode: AppMode

    var body: some View {
        VStack(spacing: 6) {
            // Period picker — styled as the first row in the metric list
            HStack {
                Text("period")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
                Spacer()
                Menu {
                    ForEach(StatsPeriodKind.menubarOptions) { p in
                        Button(p.label) {
                            viewModel.statsPeriod = p
                            viewModel.loadStatsSummary()
                        }
                    }
                } label: {
                    Text(viewModel.statsPeriod.label)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            // Mode-aware metrics
            if mode == .lock {
                MetricRow(label: "sessions", value: "\(viewModel.statsSummary.lockCount)")
                MetricRow(label: "total time", value: formatDuration(viewModel.statsSummary.totalLockedSeconds))
                if viewModel.statsSummary.lockCount > 0 {
                    MetricRow(label: "avg duration", value: formatDuration(viewModel.statsSummary.totalLockedSeconds / max(1, viewModel.statsSummary.lockCount)))
                }
                if viewModel.statsSummary.emergencyCancellations > 0 {
                    MetricRow(label: "emergency", value: "\(viewModel.statsSummary.emergencyCancellations)")
                }
            } else {
                MetricRow(label: "sessions", value: "\(viewModel.statsSummary.relaxSessionCount)")
                MetricRow(label: "session time", value: formatDuration(viewModel.statsSummary.totalRelaxSessionSeconds))
                MetricRow(label: "breaks", value: "\(viewModel.statsSummary.breakCount)")
                MetricRow(label: "break time", value: formatDuration(viewModel.statsSummary.totalBreakSeconds))
                if viewModel.statsSummary.breaksSkippedEarly > 0 {
                    MetricRow(label: "skipped early", value: "\(viewModel.statsSummary.breaksSkippedEarly)")
                }
            }

            // Link to full window
            Button(action: { viewModel.onOpenStatistics?() }) {
                HStack {
                    Text("view all statistics")
                        .font(.system(size: 10))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
