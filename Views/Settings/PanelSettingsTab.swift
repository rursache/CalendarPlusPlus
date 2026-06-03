import SwiftUI

struct PanelSettingsTab: View {
    @Bindable var controller: PanelController

    var body: some View {
        Form {
            Section {
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
            } footer: {
                Text("Pick which side of the Calendar window the panel docks to, and how wide it is")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
