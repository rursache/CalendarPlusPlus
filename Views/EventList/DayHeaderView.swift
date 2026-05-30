//
//  DayHeaderView.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI

struct DayHeaderView: View {
    let group: EventDayGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(Self.headerDateFormatter.string(from: group.date))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(group.isToday ? Color.accentColor : Color.primary)

            Text(Self.weekLabel(for: group.date))
                .font(.system(size: 13))
                .foregroundStyle(group.isToday ? Color.accentColor : Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // MARK: - Private helpers

    private static func weekLabel(for date: Date) -> String {
        let week = Calendar.current.component(.weekOfYear, from: date)
        return "W\(week)"
    }

    // "Saturday - May 31" using a hyphen to avoid em-dash issues
    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        // Custom format: full weekday, then abbreviated month + day
        f.dateFormat = "EEEE - MMM d"
        return f
    }()
}
