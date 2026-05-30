//
//  PanelIssue.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import Foundation
enum PanelIssue: Equatable {
    case calendarAccess
    case accessibility
    case noRoom
    var menuDescription: String {
        switch self {
            case .calendarAccess: "Calendar access not granted"
            case .accessibility: "Accessibility permission needed"
            case .noRoom: "No room next to the Calendar window"
        }
    }
}
