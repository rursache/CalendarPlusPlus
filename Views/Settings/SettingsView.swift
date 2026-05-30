import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var controller: PanelController

    var body: some View {
        Form {
            Section("Panel") {
                Picker("Side", selection: $controller.panelSide) {
                    ForEach(PanelSide.allCases) { Text($0.displayName).tag($0) }
                }

                Stepper(
                    value: $controller.panelWidth,
                    in: Constants.Layout.minPanelWidth...Constants.Layout.maxPanelWidth,
                    step: 10
                ) {
                    HStack {
                        Text("Width")
                        Spacer()
                        Text("\(Int(controller.panelWidth)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }

            Section("Permissions") {
                permissionRow(title: "Calendar Access", granted: controller.calendarAuthorized) {
                    controller.requestCalendarAccess()
                }
                permissionRow(title: "Accessibility", granted: controller.accessibilityGranted) {
                    controller.requestAccessibility()
                }
                permissionRow(title: "Automation", granted: controller.automationGranted) {
                    controller.requestAutomation()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 320)
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
