//
//  EventOpener.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import AppKit
import Foundation

enum EventOpener {

    /// Reveals the event in Calendar.app. Safe to call from the main actor.
    static func open(_ event: CalendarEvent) {
        if let uid = event.externalIdentifier, !uid.isEmpty {
            Task.detached {
                await openViaAppleScript(uid: uid, fallbackDate: event.startDate)
            }
        } else {
            openViaCalshow(date: event.startDate)
        }
    }

    // MARK: - Private

    // Runs AppleScript off the main thread; falls back to calshow on any error
    private static func openViaAppleScript(uid: String, fallbackDate: Date) async {
        let escapedUID = uid
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let source = """
        tell application "Calendar"
            activate
            repeat with c in every calendar
                try
                    set theEvent to first event of c where its uid = "\(escapedUID)"
                    show theEvent
                    exit repeat
                on error
                end try
            end repeat
        end tell
        """

        var errorDict: NSDictionary?
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(&errorDict)

        if let err = errorDict {
            print("[EventOpener] AppleScript error: \(err) — falling back to calshow")
            await MainActor.run { openViaCalshow(date: fallbackDate) }
        }
    }

    // calshow: navigates Calendar to the date; does not pinpoint the event
    @MainActor
    private static func openViaCalshow(date: Date) {
        let interval = date.timeIntervalSinceReferenceDate
        guard let url = URL(string: "calshow:\(interval)") else { return }
        NSWorkspace.shared.open(url)
    }
}
