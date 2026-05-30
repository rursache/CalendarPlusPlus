//
//  CalendarVisibility.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import Foundation

// Reads which calendars the user has unchecked in Calendar.app
// EventKit has no visibility flag, so we read Calendar.app's own preference
enum CalendarVisibility {

    nonisolated private static let domain = "com.apple.iCal" as CFString
    nonisolated private static let disabledKey = "DisabledCalendars" as CFString

    // EKCalendar.calendarIdentifier values currently unchecked in Calendar.app.
    // The value is a dict keyed by window name, each holding an array of identifiers,
    // and it can contain stale ids from removed accounts so callers should exclude, not allowlist
    nonisolated static func disabledCalendarIdentifiers() -> Set<String> {
        // Pull the latest from disk since another app owns this domain
        CFPreferencesAppSynchronize(domain)

        guard let raw = CFPreferencesCopyAppValue(disabledKey, domain),
              let byWindow = raw as? [String: Any] else { return [] }

        let identifiers = byWindow.values
            .compactMap { $0 as? [String] }
            .flatMap { $0 }
        return Set(identifiers)
    }
}
