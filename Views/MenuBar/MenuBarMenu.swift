import SwiftUI
import AppKit

struct MenuBarMenu: View {
    @Bindable var controller: PanelController

    var body: some View {
        Text(appInfo)
        Divider()

        if let issue = controller.issue {
            Text(issue.menuDescription)
            if issue == .accessibility {
                Button("Open Accessibility Settings") { controller.requestAccessibility() }
            } else if issue == .calendarAccess {
                Button("Grant Calendar Access") { controller.requestCalendarAccess() }
            } else if issue == .automation {
                Button("Grant Automation Access") { controller.requestAutomation() }
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

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private var appInfo: String {
        let bundle = Bundle.main
        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Calendar++"
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(name) · v\(version) (\(build))"
    }
}
