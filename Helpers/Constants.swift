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
        nonisolated static let calendarBundleIdentifier = "com.apple.iCal"

        // User-facing name, version and build pulled from the bundle
        static var displayName: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? name
        }
        static var shortVersion: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        }
        static var buildNumber: String {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        }
    }

    // MARK: - Layout

    enum Layout {
        static let panelWidth: CGFloat = 320       // default, user adjustable
        static let minPanelWidth: CGFloat = 260
        static let maxPanelWidth: CGFloat = 480
        static let panelGap: CGFloat = 10          // gap between Calendar window edge and our panel
        static let eventListTopInset: CGFloat = 4
        static let contentInset: CGFloat = 4       // rows align to the gutter, no extra per row inset
        static let panelContentPadding: CGFloat = 8  // inner gutter around the whole list, clears the rounded edges
        static let cornerRadius: CGFloat = 20      // rounded panel corners matching macOS Tahoe surfaces
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
        static let panelWidth = "panelWidth"
    }
}
