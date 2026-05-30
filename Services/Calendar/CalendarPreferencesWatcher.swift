//
//  CalendarPreferencesWatcher.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import Foundation

// Polls Calendar.app's checked-calendar state and fires when the user toggles a calendar on or off
@MainActor
final class CalendarPreferencesWatcher {

    private let onChange: () -> Void
    private var timer: Timer?
    private var lastDisabled: Set<String> = []

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func start() {
        stop()
        lastDisabled = CalendarVisibility.disabledCalendarIdentifiers()
        // A CFPreferences read is cheap, so a short poll is fine and avoids file watching edge cases
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let current = CalendarVisibility.disabledCalendarIdentifiers()
                if current != self.lastDisabled {
                    self.lastDisabled = current
                    self.onChange()
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
