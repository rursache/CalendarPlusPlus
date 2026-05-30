//
//  EventRowView.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI

struct EventRowView: View {
    let event: CalendarEvent

    var body: some View {
        if event.isAllDay {
            AllDayRow(event: event)
        } else {
            TimedRow(event: event)
        }
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
            VStack(alignment: .trailing, spacing: 1) {
                Text(EventRowView.timeFormatter.string(from: event.startDate))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.primary)

                Text(EventRowView.timeFormatter.string(from: event.endDate))
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

// MARK: - Shared formatter

extension EventRowView {
    fileprivate static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}
