//
//  PanelSide.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import Foundation

enum PanelSide: String, CaseIterable, Identifiable, Sendable {
    case auto, left, right

    var id: String { rawValue }

    var displayName: String {
        switch self {
            case .auto: "Automatic"
            case .left: "Left"
            case .right: "Right"
        }
    }
}

// Where the panel actually ended up after resolving available screen space
enum ResolvedSide: Sendable {
    case left
    case right
    case noRoom
}
