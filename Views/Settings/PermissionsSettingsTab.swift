import SwiftUI

struct PermissionsSettingsTab: View {
    @Bindable var controller: PanelController

    var body: some View {
        Form {
            Section {
                permissionRow(title: "Calendar Access", granted: controller.calendarAuthorized) {
                    controller.requestCalendarAccess()
                }
                permissionRow(title: "Accessibility", granted: controller.accessibilityGranted) {
                    controller.requestAccessibility()
                }
                permissionRow(title: "Automation", granted: controller.automationGranted) {
                    controller.requestAutomation()
                }
            } footer: {
                Text("\(Constants.App.displayName) needs these to read your events and dock the panel beside the Calendar window")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { controller.refreshAutomationStatus() }
    }

    @ViewBuilder
    private func permissionRow(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Label(title, systemImage: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(granted ? Color.green : Color.orange)
            Spacer()
            if !granted { Button("Grant", action: action) }
        }
    }
}
