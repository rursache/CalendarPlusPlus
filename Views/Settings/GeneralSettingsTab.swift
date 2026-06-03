import SwiftUI
import AppKit

struct GeneralSettingsTab: View {
    @Bindable var controller: PanelController

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Toggle("Start at Login", isOn: $controller.launchAtLogin)
                } footer: {
                    Text("Automatically open \(Constants.App.displayName) when you log in")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Pinned to the bottom of the tab, kept as a grouped section for a consistent look
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 48, height: 48)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(Constants.App.displayName)
                                .font(.headline)
                            Text("Version \(Constants.App.shortVersion) (\(Constants.App.buildNumber))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, -2)
                }
            }
            .formStyle(.grouped)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
