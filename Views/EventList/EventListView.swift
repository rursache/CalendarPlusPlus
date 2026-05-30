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
                        DayHeaderView(group: group)
                            .listRowInsets(rowInsets)
                            .background(todayTracker(for: group))
                    }
                    .id(group.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, Constants.Layout.eventListTopInset, for: .scrollContent)
            .background(Color.clear)
            .coordinateSpace(.named(Self.space))
            .onPreferenceChange(TodayMinYKey.self) { minY in
                // Defer off the layout pass, mutating state synchronously here re-enters the
                // window constraint update and trips AppKit's pass limit (crash while scrolling)
                Task { @MainActor in
                    let visible = abs(minY - Constants.Layout.eventListTopInset) > 24
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

    // Only the today header reports its position, so there is no per row geometry feedback
    @ViewBuilder
    private func todayTracker(for group: EventDayGroup) -> some View {
        if group.isToday {
            GeometryReader { geo in
                Color.clear.preference(key: TodayMinYKey.self, value: geo.frame(in: .named(Self.space)).minY)
            }
        } else {
            Color.clear
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

    private static let space = "eventList"
}

// Today header offset, defaults far off screen so the button shows when today is not rendered
private struct TodayMinYKey: PreferenceKey {
    static var defaultValue: CGFloat { .greatestFiniteMagnitude }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next != .greatestFiniteMagnitude { value = next }
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
        EventDayGroup(id: today, date: today, events: []),
        EventDayGroup(id: tomorrow, date: tomorrow, events: [allDayEvent, standup])
    ]

    return EventListView(dayGroups: dayGroups) { event in
        print("Selected: \(event.title)")
    }
    .frame(width: 320)
    .background(Color(nsColor: .windowBackgroundColor))
    .preferredColorScheme(.dark)
}
