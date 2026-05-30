//
//  PanelDisplayState.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import Foundation

// Bridges imperative panel events to the SwiftUI content
@MainActor @Observable
final class PanelDisplayState {
    // Bumped every time the panel opens so the list jumps back to today
    var scrollToTodayToken = 0
}
