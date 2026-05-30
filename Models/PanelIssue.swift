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
    case automation
    case noRoom

    var menuDescription: String {
        switch self {
            case .calendarAccess: "Calendar access not granted"
            case .accessibility: "Accessibility permission needed"
            case .automation: "Automation permission needed"
            case .noRoom: "No room next to the Calendar window"
        }
    }
}
