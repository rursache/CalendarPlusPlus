//
//  DayHeaderView.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI

struct DayHeaderView: View {
    let group: EventDayGroup
    var showTodayButton: Bool = false
    var onToday: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text(Self.headerDateFormatter.string(from: group.date))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(group.isToday ? Color.accentColor : Color.primary)

                Text(Self.weekLabel(for: group.date))
                    .font(.system(size: 13))
                    .foregroundStyle(group.isToday ? Color.accentColor : Color.secondary)
            }

            Spacer(minLength: 8)

            if showTodayButton {
                Button {
                    onToday?()
                } label: {
                    Text("Today")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
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
        f.dateFormat = "EEEE - MMM d"
        return f
    }()
}
