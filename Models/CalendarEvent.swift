//
//  CalendarEvent.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI

// Lightweight value snapshot of an EKEvent, decoupled from EventKit so the UI never touches the store directly
struct CalendarEvent: Identifiable, Hashable, Sendable {
    let id: String                   // EKEvent.eventIdentifier
    let externalIdentifier: String?  // EKEvent.calendarItemExternalIdentifier (iCal uid, used for the deep link)
    let calendarTitle: String        // owning calendar name, used to scope the AppleScript lookup
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: Color
    let location: String?
    let conference: ConferenceProvider?
}

enum ConferenceProvider: String, Hashable, Sendable, CaseIterable {
    case zoom, meet, teams, webex, facetime, skype
    case jitsi, whereby, chime, goto, bluejeans, discord, slack, around, gather
    case generic

    var displayName: String {
        switch self {
            case .zoom: "Zoom"
            case .meet: "Google Meet"
            case .teams: "Teams"
            case .webex: "Webex"
            case .facetime: "FaceTime"
            case .skype: "Skype"
            case .jitsi: "Jitsi"
            case .whereby: "Whereby"
            case .chime: "Chime"
            case .goto: "GoTo"
            case .bluejeans: "BlueJeans"
            case .discord: "Discord"
            case .slack: "Slack"
            case .around: "Around"
            case .gather: "Gather"
            case .generic: "Video"
        }
    }

    var systemImage: String { "video" }
}

// One day's worth of events, already sorted, as rendered by the panel list
struct EventDayGroup: Identifiable, Hashable, Sendable {
    let id: Date        // start of day
    let date: Date
    let events: [CalendarEvent]

    var isToday: Bool { Calendar.current.isDateInToday(date) }
}
