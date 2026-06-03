import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var controller: PanelController

    var body: some View {
        Form {
            Section("General") {
                Toggle("Start at Login", isOn: $controller.launchAtLogin)
            }

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
        .background(WindowAccessor { $0?.level = .floating })
        .onAppear {
            controller.refreshAutomationStatus()
            controller.refreshLaunchAtLogin()
            controller.setSettingsPresented(true)
        }
        .onDisappear { controller.setSettingsPresented(false) }
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

// Reaches the hosting NSWindow so we can keep Settings floating above other apps
private struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
