//
//  Constants.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import Foundation

enum Constants {

    // MARK: - App Information

    enum App {
        static let name = "CalendarPlusPlus"
        static let bundleIdentifier = Bundle.main.bundleIdentifier!
        static let calendarBundleIdentifier = "com.apple.iCal"
    }

    // MARK: - Layout

    enum Layout {
        static let panelWidth: CGFloat = 320
        static let panelGap: CGFloat = 8          // gap between Calendar window edge and our panel
        static let eventListTopInset: CGFloat = 4
        static let cornerRadius: CGFloat = 12      // rounded panel corners matching macOS Tahoe surfaces
    }

    // MARK: - Event Fetch Window

    enum Fetch {
        static let pastDays = 7
        static let futureDays = 180
    }

    // MARK: - URLs

    enum URLs {
        static let privacyPolicy = "https://randusoft.ro/pp.html"
        static let termsOfService = "https://randusoft.ro/tos.html"
        static let supportEmail = "contact@randusoft.ro"
    }

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let panelSide = "panelSide"
    }
}
