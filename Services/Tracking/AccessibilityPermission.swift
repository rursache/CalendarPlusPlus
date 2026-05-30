//
//  AccessibilityPermission.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import AppKit
import ApplicationServices

enum AccessibilityPermission {

    static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    static func requestPrompt() {
        // Trigger the system permission dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Open Accessibility pane as a fallback in case the dialog was already dismissed
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
