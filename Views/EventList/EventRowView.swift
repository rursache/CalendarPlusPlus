//
//  EventRowView.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI

struct EventRowView: View {
    let event: CalendarEvent
    var isPast: Bool = false

    var body: some View {
        Group {
            if event.isAllDay {
                AllDayRow(event: event)
            } else {
                TimedRow(event: event)
            }
        }
        .opacity(isPast ? Constants.Layout.pastEventOpacity : 1)
    }
}

// MARK: - All-day row

private struct AllDayRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 10) {
            // Soft colored circle with calendar glyph
            ZStack {
                Circle()
                    .fill(event.calendarColor.opacity(0.25))
                    .frame(width: 32, height: 32)
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(event.calendarColor)
            }

            Text(event.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("all-day")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
    }
}

// MARK: - Timed row

private struct TimedRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 8) {
            // Thin colored bar on leading edge
            RoundedRectangle(cornerRadius: 2)
                .fill(event.calendarColor)
                .frame(width: 3.5)
                .frame(maxHeight: .infinity)

            // Title + optional conference/location line
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let conference = event.conference {
                    ConferenceLabel(conference: conference)
                } else if let location = event.location, !location.isEmpty {
                    LocationLabel(location: location)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Start / end time stack on trailing edge
            // FormatStyle follows the user's locale (12h/24h, separators) and current time zone
            VStack(alignment: .trailing, spacing: 1) {
                Text(event.startDate, format: EventRowView.timeFormat)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.primary)

                Text(event.endDate, format: EventRowView.timeFormat)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 7)
        .contentShape(.rect)
    }
}

// MARK: - Small subviews for secondary info line

private struct ConferenceLabel: View {
    let conference: ConferenceProvider

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: conference.systemImage)
                .font(.system(size: 11))
            Text(conference.displayName)
                .font(.system(size: 12))
        }
        .foregroundStyle(Color.secondary)
    }
}

private struct LocationLabel: View {
    let location: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "mappin")
                .font(.system(size: 11))
            Text(location)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(Color.secondary)
    }
}

// MARK: - Shared format

extension EventRowView {
    // Locale-aware short time (honours 12h/24h and region). No fixed format string / forced locale.
    fileprivate static let timeFormat = Date.FormatStyle(date: .omitted, time: .shortened)
}
