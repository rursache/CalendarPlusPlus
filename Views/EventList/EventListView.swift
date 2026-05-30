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

    // The day section currently pinned at the top of the viewport
    @State private var topSectionID: Date?

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
                            .listRowInsets(rowInsets)
                        }
                    } header: {
                        DayHeaderView(
                            group: group,
                            showTodayButton: group.id == topSectionID && !group.isToday
                        ) {
                            scrollToToday(proxy, animated: true)
                        }
                        .listRowInsets(rowInsets)
                        .background(headerOffsetReader(for: group))
                    }
                    .id(group.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, Constants.Layout.eventListTopInset, for: .scrollContent)
            .background(Color.clear)
            .coordinateSpace(name: Self.coordinateSpace)
            .onPreferenceChange(SectionTopKey.self) { offsets in
                let newTop = Self.resolveTopSection(offsets)
                MainActor.assumeIsolated {
                    if newTop != topSectionID { topSectionID = newTop }
                }
            }
            .onChange(of: scrollTrigger) { scrollToToday(proxy, animated: true) }
            .onChange(of: todayID) { scrollToToday(proxy, animated: false) }
            .onAppear { scrollToToday(proxy, animated: false) }
        }
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: Constants.Layout.contentInset, bottom: 0, trailing: Constants.Layout.contentInset)
    }

    private func headerOffsetReader(for group: EventDayGroup) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: SectionTopKey.self,
                value: [group.id: geo.frame(in: .named(Self.coordinateSpace)).minY]
            )
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

    private static let coordinateSpace = "eventList"

    // Topmost section = last header that has reached or passed the top edge, else the first section
    private static func resolveTopSection(_ offsets: [Date: CGFloat], threshold: CGFloat = 12) -> Date? {
        let passed = offsets.filter { $0.value <= threshold }
        if let top = passed.max(by: { $0.value < $1.value }) { return top.key }
        return offsets.min(by: { $0.value < $1.value })?.key
    }
}

private struct SectionTopKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] { [:] }
    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { current, _ in current })
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
