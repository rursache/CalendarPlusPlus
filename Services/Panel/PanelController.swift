import AppKit
import EventKit
import SwiftUI

@MainActor @Observable final class PanelController {

    static let shared = PanelController()

    private(set) var issue: PanelIssue?
    var hasIssue: Bool { issue != nil }
    var calendarAuthorized: Bool { calendarService.authorizationStatus == .fullAccess }
    var accessibilityGranted: Bool { AccessibilityPermission.isGranted }

    var panelSide: PanelSide {
        didSet {
            UserDefaults.standard.set(panelSide.rawValue, forKey: Constants.UserDefaultsKeys.panelSide)
            repositionIfVisible()
        }
    }

    private let calendarService = CalendarService()
    private let focusMonitor = AppFocusMonitor()
    private let windowTracker = CalendarWindowTracker()
    private let panel = CompanionPanel()
    private var isPanelVisible = false

    private init() {
        let saved = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.panelSide)
        panelSide = saved.flatMap(PanelSide.init(rawValue:)) ?? .auto
        panel.setContent(PanelRootView(
            service: calendarService,
            onSelect: { EventOpener.open($0) },
            onRequestAccess: { [weak self] in self?.requestCalendarAccess() }
        ))
    }

    func start() {
        Task { await loadCalendar() }
        ensureAccessibilityThenTrack()
    }

    func requestCalendarAccess() {
        Task { await loadCalendar() }
    }

    func requestAccessibility() {
        AccessibilityPermission.requestPrompt()
    }

    func openCalendarApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Constants.App.calendarBundleIdentifier) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    // MARK: - Private

    private func loadCalendar() async {
        await calendarService.requestAccessAndLoad()
        refreshIssue()
    }

    private func ensureAccessibilityThenTrack() {
        if AccessibilityPermission.isGranted {
            beginTracking()
        } else {
            AccessibilityPermission.requestPrompt()
            refreshIssue()
            Task { @MainActor in
                while !AccessibilityPermission.isGranted {
                    try? await Task.sleep(for: .seconds(1))
                }
                beginTracking()
            }
        }
    }

    private func beginTracking() {
        refreshIssue()

        focusMonitor.onActivated = { [weak self] in self?.showPanel() }
        focusMonitor.onDeactivated = { [weak self] in self?.hidePanel() }
        focusMonitor.onLaunched = { [weak self] pid in self?.windowTracker.start(pid: pid) }
        focusMonitor.onTerminated = { [weak self] in
            self?.windowTracker.stop()
            self?.hidePanel()
        }
        focusMonitor.start()

        windowTracker.onFrameChange = { [weak self] _ in self?.repositionIfVisible() }
        windowTracker.onWindowGone = { [weak self] in self?.hidePanel() }

        let state = focusMonitor.currentState()
        if let pid = state.pid {
            windowTracker.start(pid: pid)
            if state.isFrontmost { showPanel() }
        }
    }

    private func showPanel() {
        guard AccessibilityPermission.isGranted,
              let frame = windowTracker.currentCalendarFrame() else {
            hidePanel()
            return
        }

        let result = PanelPlacement.compute(
            calendarFrame: frame,
            preference: panelSide,
            panelWidth: Constants.Layout.panelWidth,
            gap: Constants.Layout.panelGap,
            screens: NSScreen.screens
        )

        guard result.side != .noRoom else {
            hidePanel()
            issue = .noRoom
            return
        }

        panel.setFrame(result.frame, display: true)
        panel.orderFront(nil)
        isPanelVisible = true
        refreshIssue()
    }

    private func hidePanel() {
        panel.orderOut(nil)
        isPanelVisible = false
    }

    private func repositionIfVisible() {
        guard focusMonitor.currentState().isFrontmost else { return }
        showPanel()
    }

    private func refreshIssue() {
        if !calendarAuthorized {
            issue = .calendarAccess
        } else if !accessibilityGranted {
            issue = .accessibility
        } else {
            issue = nil
        }
    }
}

