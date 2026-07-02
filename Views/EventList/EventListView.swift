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

    // Visibility of the floating Today button, driven by the today header position
    @State private var todayButtonVisible = false

    private var todayID: Date? { dayGroups.first(where: { $0.isToday })?.id }

    var body: some View {
        // Minute ticks keep the past-event dimming current while the panel stays open
        TimelineView(.everyMinute) { timeline in
            eventList(now: timeline.date)
        }
    }

    private func eventList(now: Date) -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(dayGroups) { group in
                    Section {
                        ForEach(group.events) { event in
                            Button {
                                onSelect(event)
                            } label: {
                                EventRowView(event: event, isPast: isPast(event, in: group, now: now))
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowInsets(rowInsets)
                        }
                    } header: {
                        DayHeaderView(group: group, isPast: isPastDay(group, now: now))
                            .listRowInsets(rowInsets)
                            .background(sectionTracker(for: group))
                    }
                    .id(group.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, Constants.Layout.eventListTopInset, for: .scrollContent)
            .background(Color.clear)
            .coordinateSpace(.named(Self.space))
            .onPreferenceChange(FirstVisibleSectionKey.self) { anchor in
                // Defer off the layout pass — synchronous state mutation here re-enters AppKit's
                // window constraint update and trips the pass limit (crash while scrolling)
                Task { @MainActor in
                    let visible: Bool
                    if let anchor {
                        let atTop = abs(anchor.minY - Constants.Layout.eventListTopInset) <= 24
                                 && Calendar.current.isDateInToday(anchor.date)
                        visible = !atTop
                    } else {
                        visible = false
                    }
                    if visible != todayButtonVisible { todayButtonVisible = visible }
                }
            }
            .overlay(alignment: .topTrailing) {
                if todayButtonVisible {
                    todayButton { scrollToToday(proxy, animated: true) }
                }
            }
            .animation(.easeInOut(duration: 0.15), value: todayButtonVisible)
            .onChange(of: scrollTrigger) { scrollToToday(proxy, animated: true) }
            .onChange(of: todayID) { scrollToToday(proxy, animated: false) }
            .onAppear { scrollToToday(proxy, animated: false) }
        }
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: Constants.Layout.contentInset, bottom: 0, trailing: Constants.Layout.contentInset)
    }

    private func todayButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Today")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
        .transition(.opacity)
    }

    // Attached to every section header; provides (date, minY) for topmost-visible-section computation
    private func sectionTracker(for group: EventDayGroup) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: FirstVisibleSectionKey.self,
                value: SectionAnchor(date: group.date, minY: geo.frame(in: .named(Self.space)).minY)
            )
        }
    }

    // Ended events dim out; all-day events only once their whole day is over, so today's stay normal
    private func isPast(_ event: CalendarEvent, in group: EventDayGroup, now: Date) -> Bool {
        if isPastDay(group, now: now) { return true }
        guard group.isToday, !event.isAllDay else { return false }
        return event.endDate <= now
    }

    private func isPastDay(_ group: EventDayGroup, now: Date) -> Bool {
        group.date < Calendar.current.startOfDay(for: now)
    }

    private func scrollToToday(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let id = todayID else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(id, anchor: .top) }
        } else {
            proxy.scrollTo(id, anchor: .top)
        }
    }

    private static let space = "eventList"
}

private struct SectionAnchor: Equatable {
    let date: Date
    let minY: CGFloat
}

// Accumulates (date, minY) from every rendered section header; reduce() keeps the topmost visible one
private struct FirstVisibleSectionKey: PreferenceKey {
    static var defaultValue: SectionAnchor? { nil }
    static func reduce(value: inout SectionAnchor?, nextValue: () -> SectionAnchor?) {
        guard let next = nextValue() else { return }
        guard let current = value else { value = next; return }
        let threshold = Constants.Layout.eventListTopInset + 24
        let curOnScreen = current.minY <= threshold
        let nextOnScreen = next.minY <= threshold
        switch (curOnScreen, nextOnScreen) {
        case (true, true):   value = current.minY >= next.minY ? current : next
        case (true, false):  value = current
        case (false, true):  value = next
        case (false, false): value = current.minY <= next.minY ? current : next
        }
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

    let pastEvent = CalendarEvent(
        id: "0",
        externalIdentifier: nil,
        calendarTitle: "Work",
        title: "Yesterday's Review",
        startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: yesterday)!,
        endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: yesterday)!,
        isAllDay: false,
        calendarColor: .purple,
        location: nil,
        conference: nil
    )

    let earlyToday = CalendarEvent(
        id: "3",
        externalIdentifier: nil,
        calendarTitle: "Personal",
        title: "Morning Workout",
        startDate: calendar.date(bySettingHour: 0, minute: 5, second: 0, of: today)!,
        endDate: calendar.date(bySettingHour: 0, minute: 10, second: 0, of: today)!,
        isAllDay: false,
        calendarColor: .green,
        location: "Gym",
        conference: nil
    )

    let allDayEvent = CalendarEvent(
        id: "1",
        externalIdentifier: nil,
        calendarTitle: "Work",
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
        calendarTitle: "Work",
        title: "Daily Standup",
        startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!,
        endDate: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: tomorrow)!,
        isAllDay: false,
        calendarColor: .blue,
        location: nil,
        conference: .zoom
    )

    let dayGroups: [EventDayGroup] = [
        EventDayGroup(id: yesterday, date: yesterday, events: [pastEvent]),
        EventDayGroup(id: today, date: today, events: [earlyToday]),
        EventDayGroup(id: tomorrow, date: tomorrow, events: [allDayEvent, standup])
    ]

    return EventListView(dayGroups: dayGroups) { event in
        print("Selected: \(event.title)")
    }
    .frame(width: 320)
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.dark)
}
