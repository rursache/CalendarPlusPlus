//
//  EventOpener.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import AppKit
import ApplicationServices

// Opens the Get Info inspector for a tapped event inside Calendar.app
enum EventOpener {

    // Dedicated serial queue, NSAppleScript blocks and is not thread safe so it must stay off the main thread
    private static let queue = DispatchQueue(label: "ro.randusoft.calendarplusplus.applescript", qos: .userInitiated)

    static func open(_ event: CalendarEvent) {
        let uid = event.externalIdentifier
        let calendarTitle = event.calendarTitle
        let startDate = event.startDate

        queue.async {
            if let uid, !uid.isEmpty, showEvent(uid: uid, calendarTitle: calendarTitle) {
                // Let Calendar finish selecting before we reach for the menu
                Thread.sleep(forTimeInterval: 0.15)
                _ = openGetInfoViaAX()
            } else {
                openCalendar(toDate: startDate)
            }
        }
    }

    // MARK: - Step 1: select the event (fast, scoped to its own calendar)

    nonisolated private static func showEvent(uid: String, calendarTitle: String) -> Bool {
        let safeUID = escape(uid)
        let safeCal = escape(calendarTitle)

        // `event id <uid>` is a direct keyed reference, the `whose uid` line is a slower fallback
        let source = """
        tell application "Calendar"
            activate
            set calName to "\(safeCal)"
            set targetUID to "\(safeUID)"
            try
                show (event id targetUID of calendar calName)
                return true
            end try
            try
                show (first event of calendar calName whose uid = targetUID)
                return true
            end try
            return false
        end tell
        """

        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return false }
        return result.booleanValue
    }

    // MARK: - Step 2: open Get Info via the Edit menu using the Accessibility permission we already hold

    nonisolated private static func openGetInfoViaAX() -> Bool {
        guard let calApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: Constants.App.calendarBundleIdentifier).first else { return false }

        let axApp = AXUIElementCreateApplication(calApp.processIdentifier)
        guard let menuBar = axElement(axApp, kAXMenuBarAttribute),
              let editItem = axChildren(menuBar)?.first(where: { axTitle($0) == "Edit" }) else { return false }

        AXUIElementPerformAction(editItem, kAXPressAction as CFString)
        Thread.sleep(forTimeInterval: 0.05)   // let the menu populate

        guard let editMenu = axChildren(editItem)?.first,
              let getInfo = axChildren(editMenu)?.first(where: { axTitle($0) == "Get Info" }) else {
            AXUIElementPerformAction(editItem, kAXCancelAction as CFString)
            return false
        }

        AXUIElementPerformAction(getInfo, kAXPressAction as CFString)
        return true
    }

    // MARK: - Fallback

    nonisolated private static func openCalendar(toDate date: Date) {
        let interval = Int(date.timeIntervalSinceReferenceDate)
        guard let url = URL(string: "calshow:\(interval)") else { return }
        DispatchQueue.main.async { NSWorkspace.shared.open(url) }
    }

    // MARK: - Helpers

    nonisolated private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }

    nonisolated private static func axElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success,
              let value = ref, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    nonisolated private static func axChildren(_ element: AXUIElement) -> [AXUIElement]? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &ref) == .success,
              let array = ref as? [AXUIElement] else { return nil }
        return array
    }

    nonisolated private static func axTitle(_ element: AXUIElement) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &ref) == .success else { return nil }
        return ref as? String
    }
}
