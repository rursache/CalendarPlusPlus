import AppKit
import SwiftUI

final class CompanionPanel: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Constants.Layout.panelWidth, height: 600),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // Force the dark sidebar look regardless of the system appearance
        appearance = NSAppearance(named: .darkAqua)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func setContent<Content: View>(_ content: Content) {
        let vibrancy = NSVisualEffectView()
        vibrancy.material = .sidebar
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .active
        vibrancy.wantsLayer = true
        vibrancy.layer?.cornerRadius = Constants.Layout.cornerRadius
        vibrancy.layer?.cornerCurve = .continuous
        vibrancy.layer?.masksToBounds = true
        contentView = vibrancy

        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // Our edge pins fully determine the frame, so stop the hosting view from deriving
        // sizing constraints from SwiftUI content. Prevents an Update Constraints loop during scroll
        hosting.sizingOptions = []
        vibrancy.addSubview(hosting)

        // Uniform inner gutter so the list never touches the rounded panel edges
        let pad = Constants.Layout.panelContentPadding
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: vibrancy.topAnchor, constant: pad),
            hosting.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor, constant: pad),
            hosting.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor, constant: -pad),
            hosting.bottomAnchor.constraint(equalTo: vibrancy.bottomAnchor, constant: -pad)
        ])
    }
}
