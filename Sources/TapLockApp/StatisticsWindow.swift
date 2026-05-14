import Cocoa
import SwiftUI
import TapLockAppLib
import TapLockCore

// MARK: - Window Controller

final class StatisticsWindowController: NSWindowController {
    init(viewModel: MenuBarViewModel) {
        let view = StatisticsView(viewModel: viewModel)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "TapLock Statistics"
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 540, height: 520))
        window.minSize = NSSize(width: 480, height: 400)
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Root View

struct StatisticsView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var selectedMode: AppMode = .lock

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 14) {
                Picker("", selection: $selectedMode) {
                    Label("Lock", systemImage: "lock.fill").tag(AppMode.lock)
                    Label("Relax", systemImage: "leaf.fill").tag(AppMode.relax)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                HStack(spacing: 12) {
                    Text("Period")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Picker("", selection: $viewModel.statsPeriod) {
                        ForEach(StatsPeriodKind.allCases) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                    .onChange(of: viewModel.statsPeriod) { _ in
                        viewModel.loadStatsSummary()
                    }

                    if viewModel.statsPeriod == .custom {
                        DatePicker("", selection: $viewModel.statsCustomStart, displayedComponents: .date)
                            .labelsHidden()
                            .onChange(of: viewModel.statsCustomStart) { _ in
                                viewModel.loadStatsSummary()
                            }
                        Text("→")
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.statsCustomEnd, displayedComponents: .date)
                            .labelsHidden()
                            .onChange(of: viewModel.statsCustomEnd) { _ in
                                viewModel.loadStatsSummary()
                            }
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Metric tiles
            ScrollView {
                if selectedMode == .lock {
                    LockMetricsGrid(summary: viewModel.statsSummary)
                        .padding(20)
                } else {
                    RelaxMetricsGrid(summary: viewModel.statsSummary)
                        .padding(20)
                }
            }

            Divider()

            HStack {
                Text(StatsStore.shared.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.head)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .onAppear {
            viewModel.loadStatsSummary()
        }
    }
}

// MARK: - Metric Grids

struct LockMetricsGrid: View {
    let summary: StatsSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            MetricTile(label: "Sessions", value: "\(summary.lockCount)")
            MetricTile(label: "Total Time",
                       value: summary.lockCount > 0 ? formatDuration(summary.totalLockedSeconds) : "—")
            MetricTile(label: "Average Duration",
                       value: summary.lockCount > 0 ? formatDuration(summary.totalLockedSeconds / max(1, summary.lockCount)) : "—")
            MetricTile(label: "Emergency Cancels", value: "\(summary.emergencyCancellations)")
        }
    }
}

struct RelaxMetricsGrid: View {
    let summary: StatsSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            MetricTile(label: "Sessions", value: "\(summary.relaxSessionCount)")
            MetricTile(label: "Total Session Time",
                       value: summary.relaxSessionCount > 0 ? formatDuration(summary.totalRelaxSessionSeconds) : "—")
            MetricTile(label: "Breaks Delivered", value: "\(summary.breakCount)")
            MetricTile(label: "Total Break Time",
                       value: summary.breakCount > 0 ? formatDuration(summary.totalBreakSeconds) : "—")
            MetricTile(label: "Skipped Early", value: "\(summary.breaksSkippedEarly)")
            MetricTile(label: "Skip Rate",
                       value: summary.breakCount > 0
                       ? "\(Int(round(Double(summary.breaksSkippedEarly) / Double(summary.breakCount) * 100)))%"
                       : "—")
        }
    }
}

// MARK: - Tile

struct MetricTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(0.6)

            Text(value)
                .font(.system(size: 30, weight: .light, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }
}
