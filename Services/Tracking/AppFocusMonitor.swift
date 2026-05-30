//
//  AppFocusMonitor.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import AppKit

@MainActor final class AppFocusMonitor {

    var onActivated: (() -> Void)?
    var onDeactivated: (() -> Void)?
    var onLaunched: ((pid_t) -> Void)?
    var onTerminated: (() -> Void)?

    private var observers: [NSObjectProtocol] = []

    func start() {
        let nc = NSWorkspace.shared.notificationCenter

        let activated = nc.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == Constants.App.calendarBundleIdentifier else { return }
            MainActor.assumeIsolated { self?.onActivated?() }
        }

        let deactivated = nc.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == Constants.App.calendarBundleIdentifier else { return }
            MainActor.assumeIsolated { self?.onDeactivated?() }
        }

        let launched = nc.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == Constants.App.calendarBundleIdentifier else { return }
            let pid = app.processIdentifier
            MainActor.assumeIsolated { self?.onLaunched?(pid) }
        }

        let terminated = nc.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == Constants.App.calendarBundleIdentifier else { return }
            MainActor.assumeIsolated { self?.onTerminated?() }
        }

        observers = [activated, deactivated, launched, terminated]
    }

    func stop() {
        let nc = NSWorkspace.shared.notificationCenter
        observers.forEach { nc.removeObserver($0) }
        observers = []
    }

    func currentState() -> (isRunning: Bool, pid: pid_t?, isFrontmost: Bool) {
        let running = NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == Constants.App.calendarBundleIdentifier
        }
        guard let app = running else {
            return (false, nil, false)
        }
        return (true, app.processIdentifier, app.isActive)
    }
}
