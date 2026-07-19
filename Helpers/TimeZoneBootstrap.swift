//
//  TimeZoneBootstrap.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import Foundation

// Launchers like Raycast can inherit TZ=UTC into GUI apps. Foundation then treats
// TimeZone.current as GMT and event times render hours off. Finder launches do not
// set TZ, which is why the same binary looks correct when opened from /Applications.
// Clear a pinned TZ once at startup and re-read the Mac's real system zone.
enum TimeZoneBootstrap {
    static func ensureSystemTimeZone() {
        if getenv("TZ") != nil {
            unsetenv("TZ")
        }
        CFTimeZoneResetSystem()
        NSTimeZone.resetSystemTimeZone()
    }
}
