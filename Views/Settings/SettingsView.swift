import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var controller: PanelController

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettingsTab(controller: controller)
            }
            Tab("Panel", systemImage: "sidebar.squares.left") {
                PanelSettingsTab(controller: controller)
            }
            Tab("Permissions", systemImage: "lock.shield") {
                PermissionsSettingsTab(controller: controller)
            }
        }
        .frame(width: 460, height: 320)
        .background(WindowAccessor { $0?.level = .floating })
        .onAppear {
            controller.refreshAutomationStatus()
            controller.refreshLaunchAtLogin()
            controller.setSettingsPresented(true)
        }
        .onDisappear { controller.setSettingsPresented(false) }
    }
}

// Reaches the hosting NSWindow so we can keep Settings floating above other apps
struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
