// MenuBarLabel.swift
// Shows a calendar icon that reflects the current issue state

import SwiftUI

struct MenuBarLabel: View {
    let hasIssue: Bool

    var body: some View {
        Image(systemName: hasIssue ? "calendar.badge.exclamationmark" : "calendar")
            .font(.system(size: 18))
    }
}
