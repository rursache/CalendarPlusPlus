//
//  App.swift
//
//  Created by Radu Ursache (RanduSoft)
//

import SwiftUI
import RSEssentials

@main
struct CalendarPlusPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var controller = PanelController.shared

    init() {
        // Before any date formatting: undo TZ inherited from launchers (e.g. Raycast sets TZ=UTC)
        TimeZoneBootstrap.ensureSystemTimeZone()

        RSEssentialsEngine.shared.setup(
            loggerConfig: .init(),
            updateCheckConfig: .init(),
            analyticsConfig: .init()
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(controller: controller)
        } label: {
            MenuBarLabel(hasIssue: controller.hasIssue)
        }

        Settings {
            SettingsView(controller: controller)
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        PanelController.shared.start()
    }
}
