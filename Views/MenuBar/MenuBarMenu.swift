import SwiftUI
import AppKit

struct MenuBarMenu: View {
    @Bindable var controller: PanelController

    var body: some View {
        if let issue = controller.issue {
            Text(issue.menuDescription)
            if issue == .accessibility {
                Button("Open Accessibility Settings") { controller.requestAccessibility() }
            } else if issue == .calendarAccess {
                Button("Grant Calendar Access") { controller.requestCalendarAccess() }
            }
            Divider()
        }

        Picker("Panel Side", selection: $controller.panelSide) {
            ForEach(PanelSide.allCases) { side in
                Text(side.displayName).tag(side)
            }
        }

        Button("Open Calendar") { controller.openCalendarApp() }

        Divider()

        SettingsLink { Text("Settings...") }

        Button("Quit Calendar++") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
