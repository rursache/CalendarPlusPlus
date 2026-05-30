import AppKit
import EventKit
import QuartzCore
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
    private let displayState = PanelDisplayState()
    private var isPanelVisible = false

    private init() {
        let saved = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.panelSide)
        panelSide = saved.flatMap(PanelSide.init(rawValue:)) ?? .left
        panel.setContent(PanelRootView(
            service: calendarService,
            display: displayState,
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

        windowTracker.onFrameChange = { [weak self] frame in self?.followCalendar(to: frame) }
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
        place(calendarFrame: frame, animated: false)
    }

    // Live follow during a Calendar window drag, smoothly animated to keep up
    private func followCalendar(to frame: NSRect) {
        guard focusMonitor.currentState().isFrontmost else { return }
        place(calendarFrame: frame, animated: true)
    }

    private func place(calendarFrame: NSRect, animated: Bool) {
        let result = PanelPlacement.compute(
            calendarFrame: calendarFrame,
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

        let wasVisible = isPanelVisible
        setPanelFrame(result.frame, animated: animated && wasVisible)

        if !wasVisible {
            panel.orderFront(nil)
            panel.invalidateShadow()
            isPanelVisible = true
            // Jump back to today every time the panel opens
            displayState.scrollToTodayToken += 1
        }
        refreshIssue()
    }

    private func setPanelFrame(_ frame: NSRect, animated: Bool) {
        guard animated else {
            panel.setFrame(frame, display: true)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func hidePanel() {
        panel.orderOut(nil)
        isPanelVisible = false
    }

    private func repositionIfVisible() {
        guard isPanelVisible,
              focusMonitor.currentState().isFrontmost,
              let frame = windowTracker.currentCalendarFrame() else { return }
        place(calendarFrame: frame, animated: true)
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

