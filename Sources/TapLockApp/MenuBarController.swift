import Cocoa
import SwiftUI
import TapLockAppLib
import TapLockCore

// MARK: - Menu Bar Controller

final class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private let viewModel = MenuBarViewModel()
    private var menuBarTimer: Timer?
    private var statisticsWindowController: StatisticsWindowController?

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

        viewModel.onOpenStatistics = { [weak self] in
            self?.openStatistics()
        }
    }

    private func openStatistics() {
        if statisticsWindowController == nil {
            statisticsWindowController = StatisticsWindowController(viewModel: viewModel)
        }
        statisticsWindowController?.show()
        popover.performClose(nil)
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
            viewModel.loadStatsSummary()
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onDisappear {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }
}
