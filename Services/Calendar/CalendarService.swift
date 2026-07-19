//
//  CalendarService.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import EventKit
import SwiftUI

@MainActor @Observable
final class CalendarService {

    private(set) var dayGroups: [EventDayGroup] = []
    private(set) var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

    private let store = EKEventStore()
    // Block-based observer token for EKEventStoreChanged, kept for the app lifetime
    private var storeObserver: NSObjectProtocol?
    private var prefsWatcher: CalendarPreferencesWatcher?

    init() {
        storeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reload()
            }
        }

        // Reload when the user checks or unchecks a calendar in Calendar.app
        prefsWatcher = CalendarPreferencesWatcher { [weak self] in
            self?.reload()
        }
        prefsWatcher?.start()
    }

    func requestAccessAndLoad() async {
        do {
            _ = try await store.requestFullAccessToEvents()
        } catch {
            // Access denied or restricted, status is refreshed below regardless
        }
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        reload()
    }

    func reload() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard authorizationStatus == .fullAccess else {
            dayGroups = []
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -Constants.Fetch.pastDays, to: today)!
        let end = calendar.date(byAdding: .day, value: Constants.Fetch.futureDays, to: today)!

        // Respect the calendars the user has checked in Calendar.app
        let disabled = CalendarVisibility.disabledCalendarIdentifiers()
        let visibleCalendars = store.calendars(for: .event)
            .filter { !disabled.contains($0.calendarIdentifier) }

        let ekEvents: [EKEvent]
        if visibleCalendars.isEmpty {
            ekEvents = []
        } else {
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: visibleCalendars)
            ekEvents = store.events(matching: predicate)
        }

        let events = ekEvents.map { mapEvent($0) }

        // Expand multi-day events onto every calendar day they overlap (all-day ends are exclusive)
        var grouped: [Date: [CalendarEvent]] = [:]
        for event in events {
            for day in Self.daysOverlapping(event, calendar: calendar, from: start, to: end) {
                grouped[day, default: []].append(event)
            }
        }

        // Always include today even with no events
        if grouped[today] == nil {
            grouped[today] = []
        }

        dayGroups = grouped
            .map { day, dayEvents in EventDayGroup(id: day, date: day, events: Self.sortWithinDay(dayEvents)) }
            .sorted { $0.date < $1.date }
    }

    // All-day events first, then timed events ascending by start
    private static func sortWithinDay(_ events: [CalendarEvent]) -> [CalendarEvent] {
        let allDay = events.filter { $0.isAllDay }.sorted { $0.startDate < $1.startDate }
        let timed = events.filter { !$0.isAllDay }.sorted { $0.startDate < $1.startDate }
        return allDay + timed
    }

    // Calendar days in [from, to) that the event covers. All-day EventKit ends are exclusive
    // (a 1-day all-day on Jul 20 has end = Jul 21 00:00 and only lands on Jul 20).
    private static func daysOverlapping(
        _ event: CalendarEvent,
        calendar: Calendar,
        from rangeStart: Date,
        to rangeEnd: Date
    ) -> [Date] {
        guard event.endDate > rangeStart, event.startDate < rangeEnd else { return [] }

        let eventFirstDay = calendar.startOfDay(for: event.startDate)
        var day = eventFirstDay < rangeStart ? rangeStart : eventFirstDay
        var days: [Date] = []

        while day < rangeEnd {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            if event.startDate < dayEnd && event.endDate > day {
                days.append(day)
            }
            if event.endDate <= dayEnd { break }
            day = dayEnd
        }
        return days
    }

    // MARK: - Private helpers

    private func mapEvent(_ event: EKEvent) -> CalendarEvent {
        let conferenceProvider = detectConference(event)
        let location = cleanLocation(event.location, conference: conferenceProvider)

        let color: Color
        if let cgColor = event.calendar?.cgColor {
            color = Color(cgColor)
        } else {
            color = .accentColor
        }

        return CalendarEvent(
            id: event.eventIdentifier ?? UUID().uuidString,
            externalIdentifier: event.calendarItemExternalIdentifier,
            calendarTitle: event.calendar?.title ?? "",
            title: event.title ?? "",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            calendarColor: color,
            location: location,
            conference: conferenceProvider
        )
    }

    // Domain markers checked against location, url and notes; first match wins
    nonisolated private static let providerMarkers: [(ConferenceProvider, [String])] = [
        (.zoom, ["zoom.us", "zoom.com"]),
        (.meet, ["meet.google"]),
        (.teams, ["teams.microsoft", "teams.live"]),
        (.webex, ["webex"]),
        (.facetime, ["facetime"]),
        (.skype, ["skype"]),
        (.jitsi, ["meet.jit.si", "jitsi"]),
        (.whereby, ["whereby.com"]),
        (.chime, ["chime.aws"]),
        (.goto, ["gotomeeting", "meet.goto.com"]),
        (.bluejeans, ["bluejeans"]),
        (.discord, ["discord.gg", "discord.com"]),
        (.slack, ["slack.com/huddle"]),
        (.around, ["around.co"]),
        (.gather, ["gather.town"])
    ]

    // Tokens that make an unknown URL plausibly a meeting link rather than a plain webpage
    nonisolated private static let meetingURLKeywords = [
        "meet", "join", "call", "video", "conference", "webinar", "room", "huddle"
    ]

    private func detectConference(_ event: EKEvent) -> ConferenceProvider? {
        let candidates: [String] = [
            event.location,
            event.url?.absoluteString,
            event.notes
        ].compactMap { $0 }.map { $0.lowercased() }

        for text in candidates {
            for (provider, markers) in Self.providerMarkers where markers.contains(where: text.contains) {
                return provider
            }
        }

        // Unknown provider: a URL pasted as the location is almost always a join link
        if let location = event.location?.lowercased(), Self.looksLikeURL(location) {
            return .generic
        }

        // The url field is often a plain webpage, only badge it when it looks meeting-shaped
        if let url = event.url?.absoluteString.lowercased(),
           Self.meetingURLKeywords.contains(where: url.contains) {
            return .generic
        }

        return nil
    }

    // Strip location when it is just a video/conference URL to avoid redundancy with the conference badge
    private func cleanLocation(_ location: String?, conference: ConferenceProvider?) -> String? {
        guard let location, !location.isEmpty else { return nil }
        guard conference != nil else { return location }
        if Self.looksLikeURL(location.lowercased()) {
            return nil
        }
        return location
    }

    // Treat it as a raw URL if it starts with a scheme or www; expects lowercased input
    nonisolated private static func looksLikeURL(_ text: String) -> Bool {
        text.hasPrefix("http://") || text.hasPrefix("https://") || text.hasPrefix("www.")
    }
}
