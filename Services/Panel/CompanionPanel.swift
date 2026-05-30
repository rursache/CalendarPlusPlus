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
        vibrancy.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: vibrancy.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: vibrancy.bottomAnchor)
        ])
    }
}
