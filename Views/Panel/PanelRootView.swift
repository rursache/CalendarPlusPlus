import SwiftUI
import EventKit

struct PanelRootView: View {
    let service: CalendarService
    var onSelect: (CalendarEvent) -> Void
    var onRequestAccess: () -> Void

    var body: some View {
        Group {
            if service.authorizationStatus == .fullAccess {
                EventListView(dayGroups: service.dayGroups, onSelect: onSelect)
            } else {
                ContentUnavailableView {
                    Label("Calendar Access Needed", systemImage: "calendar.badge.exclamationmark")
                } description: {
                    Text("Allow Calendar++ to read your events to show them here")
                } actions: {
                    Button("Grant Access", action: onRequestAccess)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
    }
}
