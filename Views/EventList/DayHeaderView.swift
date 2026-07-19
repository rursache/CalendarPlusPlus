//
//  DayHeaderView.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI

struct DayHeaderView: View {
    let group: EventDayGroup
    var isPast: Bool = false
    var showTodayButton: Bool = false
    var onToday: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                // Locale-aware weekday + month/day (order and names follow the user)
                Text(group.date, format: Self.headerFormat)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(group.isToday ? Color.accentColor : Color.primary)

                Text(Self.weekLabel(for: group.date))
                    .font(.system(size: 13))
                    .foregroundStyle(group.isToday ? Color.accentColor : Color.secondary)
            }
            .opacity(isPast ? Constants.Layout.pastEventOpacity : 1)

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

    // e.g. en: "Sunday, Jul 19" · ro: "duminică, 19 iul." (system decides order and separators)
    private static let headerFormat = Date.FormatStyle()
        .weekday(.wide)
        .month(.abbreviated)
        .day()
}
