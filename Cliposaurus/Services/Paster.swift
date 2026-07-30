// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import AppKit
import ApplicationServices

/// Simulates `Cmd+V` in the previously active app and wraps the required
/// Accessibility permission.
enum Paster {
    /// Virtual key code of the "V" key (ANSI).
    private static let vKeyCode: CGKeyCode = 0x09

    /// Is the app granted Accessibility access (a prerequisite for keyboard simulation)?
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system permission dialog – if not already granted.
    @discardableResult
    static func requestPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Sends a `Cmd+V` to the currently active application.
    ///
    /// Returns `false` if permission is missing (in that case the permission dialog was
    /// triggered and the content is already sitting ready in the clipboard).
    @discardableResult
    static func paste() -> Bool {
        guard isTrusted else {
            requestPermission()
            return false
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        else { return false }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
        return true
    }
}
