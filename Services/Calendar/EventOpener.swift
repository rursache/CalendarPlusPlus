//
//  EventOpener.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import AppKit
import CoreGraphics

// Opens the Get Info inspector for a tapped event inside Calendar.app
enum EventOpener {

    // Dedicated serial queue, NSAppleScript blocks and is not thread safe so it must stay off the main thread
    private static let queue = DispatchQueue(label: "ro.randusoft.calendarplusplus.applescript", qos: .userInitiated)

    static func open(_ event: CalendarEvent) {
        let uid = event.externalIdentifier
        let calendarTitle = event.calendarTitle
        let startDate = event.startDate

        queue.async {
            if let uid, !uid.isEmpty, showEvent(uid: uid, calendarTitle: calendarTitle) {
                // Let Calendar finish selecting and come frontmost before the shortcut
                Thread.sleep(forTimeInterval: 0.15)
                pressGetInfo()
            } else {
                openCalendar(toDate: startDate)
            }
        }
    }

    // MARK: - Step 1: select the event (fast, scoped to its own calendar)

    nonisolated private static func showEvent(uid: String, calendarTitle: String) -> Bool {
        let safeUID = escape(uid)
        let safeCal = escape(calendarTitle)

        // `event id <uid>` is a direct keyed reference, the `whose uid` line is a slower fallback
        let source = """
        tell application "Calendar"
            activate
            set calName to "\(safeCal)"
            set targetUID to "\(safeUID)"
            try
                show (event id targetUID of calendar calName)
                return true
            end try
            try
                show (first event of calendar calName whose uid = targetUID)
                return true
            end try
            return false
        end tell
        """

        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return false }
        return result.booleanValue
    }

    // MARK: - Step 2: open Get Info on the selected event with Command-I

    // Command-I is Calendar's "Get Info" shortcut (Option-Command-I is the inspector). Posting a key event
    // uses the Accessibility permission we already hold and avoids fiddly menu traversal
    nonisolated private static func pressGetInfo() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let iKey: CGKeyCode = 34   // kVK_ANSI_I
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: iKey, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: iKey, keyDown: false) else { return }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
    }

    // MARK: - Fallback

    nonisolated private static func openCalendar(toDate date: Date) {
        let interval = Int(date.timeIntervalSinceReferenceDate)
        guard let url = URL(string: "calshow:\(interval)") else { return }
        DispatchQueue.main.async { NSWorkspace.shared.open(url) }
    }

    // MARK: - Helpers

    nonisolated private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
