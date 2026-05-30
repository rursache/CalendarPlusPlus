//
//  EventListView.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI

struct EventListView: View {
    let dayGroups: [EventDayGroup]
    var onSelect: (CalendarEvent) -> Void
    var scrollTrigger: Int = 0

    private var todayID: Date? { dayGroups.first(where: { $0.isToday })?.id }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(dayGroups) { group in
                    Section {
                        ForEach(group.events) { event in
                            Button {
                                onSelect(event)
                            } label: {
                                EventRowView(event: event)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                        }
                    } header: {
                        DayHeaderView(group: group, showTodayButton: !group.isToday) {
                            scrollToToday(proxy, animated: true)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                    }
                    .id(group.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, Constants.Layout.eventListTopInset, for: .scrollContent)
            .background(Color.clear)
            .onChange(of: scrollTrigger) { scrollToToday(proxy, animated: true) }
            .onChange(of: todayID) { scrollToToday(proxy, animated: false) }
            .onAppear { scrollToToday(proxy, animated: false) }
        }
    }

    private func scrollToToday(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let id = todayID else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(id, anchor: .top) }
        } else {
            proxy.scrollTo(id, anchor: .top)
        }
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

    let allDayEvent = CalendarEvent(
        id: "1",
        externalIdentifier: nil,
        title: "Radu's Birthday",
        startDate: tomorrow,
        endDate: tomorrow,
        isAllDay: true,
        calendarColor: .orange,
        location: nil,
        conference: nil
    )

    let standup = CalendarEvent(
        id: "2",
        externalIdentifier: nil,
        title: "Daily Standup",
        startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!,
        endDate: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: tomorrow)!,
        isAllDay: false,
        calendarColor: .blue,
        location: nil,
        conference: .zoom
    )

    let designReview = CalendarEvent(
        id: "3",
        externalIdentifier: nil,
        title: "Design Review - CalendarPlusPlus panel UI",
        startDate: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow)!,
        endDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: tomorrow)!,
        isAllDay: false,
        calendarColor: .purple,
        location: "Bucharest HQ, Room 3",
        conference: nil
    )

    let dayGroups: [EventDayGroup] = [
        EventDayGroup(id: today, date: today, events: []),
        EventDayGroup(id: tomorrow, date: tomorrow, events: [allDayEvent, standup, designReview])
    ]

    return EventListView(dayGroups: dayGroups) { event in
        print("Selected: \(event.title)")
    }
    .frame(width: 320)
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.dark)
}
