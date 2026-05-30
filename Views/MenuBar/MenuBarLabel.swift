// MenuBarLabel.swift
// Shows a calendar icon that reflects the current issue state

import SwiftUI
import AppKit

struct MenuBarLabel: View {
    let hasIssue: Bool

    var body: some View {
        Image(nsImage: Self.icon(hasIssue: hasIssue))
    }

    // A template NSImage with an explicit point size sizes reliably in the menu bar,
    // unlike .font/.imageScale on a SwiftUI Image which the menu bar partly overrides
    private static func icon(hasIssue: Bool) -> NSImage {
        let name = hasIssue ? "calendar.badge.exclamationmark" : "calendar"
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            .applying(NSImage.SymbolConfiguration(scale: .large))
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Calendar++")?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image ?? NSImage()
    }
}
