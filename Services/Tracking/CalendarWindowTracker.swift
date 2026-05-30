//
//  CalendarWindowTracker.swift
//  CalendarPlusPlus
//
//  Created by Radu Ursache (RanduSoft)
//

import AppKit
import ApplicationServices

// Global C-compatible callback -- cannot capture context, so we recover the tracker via userdata
nonisolated let axCallback: AXObserverCallback = { _, element, notification, userdata in
    guard let userdata else { return }
    let tracker = Unmanaged<CalendarWindowTracker>.fromOpaque(userdata).takeUnretainedValue()

    // AX notifications arrive on the main run loop, so MainActor isolation is already satisfied
    MainActor.assumeIsolated {
        tracker.handle(element: element, notification: notification as String)
    }
}

@MainActor final class CalendarWindowTracker {

    var onFrameChange: ((NSRect) -> Void)?
    var onWindowGone: (() -> Void)?

    private var observer: AXObserver?
    private var appElement: AXUIElement?
    private var windowElement: AXUIElement?
    private var pid: pid_t = 0

    // MARK: - Public API

    func start(pid: pid_t) {
        stop()
        self.pid = pid

        let app = AXUIElementCreateApplication(pid)
        appElement = app

        var obs: AXObserver?
        guard AXObserverCreate(pid, axCallback, &obs) == .success, let obs else { return }
        observer = obs

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // App-level notifications let us react when the main window switches
        AXObserverAddNotification(obs, app, kAXFocusedWindowChangedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, app, kAXWindowCreatedNotification as CFString, selfPtr)

        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(obs), .defaultMode)

        // Attach to whatever window is already frontmost
        if let win = resolveMainWindow() {
            registerWindowNotifications(on: win)
        }
    }

    func stop() {
        if let obs = observer {
            let src = AXObserverGetRunLoopSource(obs)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .defaultMode)
        }
        observer = nil
        appElement = nil
        windowElement = nil
        pid = 0
    }

    func currentCalendarFrame() -> NSRect? {
        guard let win = windowElement ?? resolveMainWindow() else { return nil }
        return axFrame(of: win)
    }

    // MARK: - Internal

    // Called from the global AX callback on the main actor
    func handle(element: AXUIElement, notification: String) {
        if notification == (kAXMovedNotification as String)
            || notification == (kAXResizedNotification as String)
            || notification == (kAXWindowDeminiaturizedNotification as String) {
            let target = windowElement ?? element
            if let frame = axFrame(of: target) {
                onFrameChange?(frame)
            }
        } else if notification == (kAXWindowMiniaturizedNotification as String)
                    || notification == (kAXUIElementDestroyedNotification as String) {
            windowElement = nil
            onWindowGone?()
        } else if notification == (kAXFocusedWindowChangedNotification as String)
                    || notification == (kAXWindowCreatedNotification as String) {
            // Re-resolve and re-register so we track the new frontmost window
            if let win = resolveMainWindow() {
                registerWindowNotifications(on: win)
                if let frame = axFrame(of: win) {
                    onFrameChange?(frame)
                }
            }
        }
    }

    // MARK: - Helpers

    private func resolveMainWindow() -> AXUIElement? {
        guard let app = appElement else { return nil }

        // Prefer kAXMainWindowAttribute; fall back to focused window
        for attr in [kAXMainWindowAttribute, kAXFocusedWindowAttribute] {
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(app, attr as CFString, &value) == .success,
                  let val = value,
                  CFGetTypeID(val) == AXUIElementGetTypeID() else { continue }
            // swiftlint:disable:next force_cast
            return (val as! AXUIElement)
        }
        return nil
    }

    private func registerWindowNotifications(on win: AXUIElement) {
        guard let obs = observer else { return }
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // Remove previous window-level observations if we had a different window
        if let prev = windowElement {
            AXObserverRemoveNotification(obs, prev, kAXMovedNotification as CFString)
            AXObserverRemoveNotification(obs, prev, kAXResizedNotification as CFString)
            AXObserverRemoveNotification(obs, prev, kAXWindowMiniaturizedNotification as CFString)
            AXObserverRemoveNotification(obs, prev, kAXWindowDeminiaturizedNotification as CFString)
            AXObserverRemoveNotification(obs, prev, kAXUIElementDestroyedNotification as CFString)
        }

        windowElement = win

        AXObserverAddNotification(obs, win, kAXMovedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, win, kAXResizedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, win, kAXWindowMiniaturizedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, win, kAXWindowDeminiaturizedNotification as CFString, selfPtr)
        AXObserverAddNotification(obs, win, kAXUIElementDestroyedNotification as CFString, selfPtr)
    }

    // Reads position + size from an AX window element and flips to Cocoa coordinates
    private func axFrame(of win: AXUIElement) -> NSRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posVal = posRef, let sizeVal = sizeRef else { return nil }

        var axOrigin = CGPoint.zero
        var axSize = CGSize.zero
        // AXValueGetValue returns Bool -- true on success
        guard AXValueGetValue(posVal as! AXValue, .cgPoint, &axOrigin),
              AXValueGetValue(sizeVal as! AXValue, .cgSize, &axSize) else { return nil }

        // Flip from top-left (AX/Quartz) to bottom-left (Cocoa/NSWindow) using tallest screen
        let maxY = NSScreen.screens.map { $0.frame.maxY }.max() ?? 0
        let cocoaY = maxY - axOrigin.y - axSize.height

        return NSRect(x: axOrigin.x, y: cocoaY, width: axSize.width, height: axSize.height)
    }
}
