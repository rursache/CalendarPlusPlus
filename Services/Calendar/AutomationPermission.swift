//
//  AutomationPermission.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import AppKit
import CoreServices

// Wraps the TCC "Apple Events" permission that lets us drive Calendar.app via AppleScript
enum AutomationPermission {

    enum Status: Sendable {
        case granted
        case denied
        case notDetermined
        case targetNotRunning

        var isGranted: Bool { self == .granted }
    }

    nonisolated private static let calendarBundleID = Constants.App.calendarBundleIdentifier

    nonisolated private static var isCalendarRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: calendarBundleID).isEmpty
    }

    // Blocking TCC query. With askUser true this shows the consent dialog and blocks, so keep it off the main thread
    nonisolated static func status(askUser: Bool) -> Status {
        let descriptor = NSAppleEventDescriptor(bundleIdentifier: calendarBundleID)
        guard let rawDesc = descriptor.aeDesc else { return .notDetermined }
        var target = rawDesc.pointee
        defer { AEDisposeDesc(&target) }

        let result = AEDeterminePermissionToAutomateTarget(&target, typeWildCard, typeWildCard, askUser)
        switch result {
            case noErr: return .granted
            case OSStatus(errAEEventNotPermitted): return .denied
            case OSStatus(errAEEventWouldRequireUserConsent): return .notDetermined
            case OSStatus(procNotFound): return .targetNotRunning
            default: return .notDetermined
        }
    }

    // Non prompting status read for the settings UI
    nonisolated static func currentStatus() async -> Status {
        await Task.detached { status(askUser: false) }.value
    }

    // Triggers the consent prompt, optionally launching Calendar first since the query needs it running
    nonisolated static func request(launchIfNeeded: Bool) async -> Status {
        if !isCalendarRunning {
            guard launchIfNeeded else { return .targetNotRunning }
            await launchCalendar()
            try? await Task.sleep(for: .milliseconds(700))
        }
        return await Task.detached { status(askUser: true) }.value
    }

    nonisolated private static func launchCalendar() async {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: calendarBundleID) else { return }
        _ = try? await NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
