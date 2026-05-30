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

        // Build a dict keyed by start-of-day
        var grouped: [Date: [CalendarEvent]] = [:]
        for event in events {
            let day = calendar.startOfDay(for: event.startDate)
            grouped[day, default: []].append(event)
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

    private func detectConference(_ event: EKEvent) -> ConferenceProvider? {
        let candidates: [String] = [
            event.location,
            event.url?.absoluteString,
            event.notes
        ].compactMap { $0 }.map { $0.lowercased() }

        for text in candidates {
            if text.contains("zoom.us") || text.contains("zoom.com") { return .zoom }
            if text.contains("meet.google") { return .meet }
            if text.contains("teams.microsoft") || text.contains("teams.live") { return .teams }
            if text.contains("webex") { return .webex }
            if text.contains("facetime") || text.contains("apple.com/facetime") { return .facetime }
            if text.contains("skype") { return .skype }
        }

        // If there is a URL but it matched nothing, treat as generic video link
        if event.url != nil {
            return .generic
        }

        return nil
    }

    // Strip location when it is just a video/conference URL to avoid redundancy with the conference badge
    private func cleanLocation(_ location: String?, conference: ConferenceProvider?) -> String? {
        guard let location, !location.isEmpty else { return nil }
        guard conference != nil else { return location }
        // Treat it as a raw URL if it starts with a scheme or www
        let lower = location.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("www.") {
            return nil
        }
        return location
    }
}
