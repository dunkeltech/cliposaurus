// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import Foundation
import ServiceManagement

/// Wraps "launch at login" via the modern `SMAppService` API (macOS 13+).
enum LoginItem {
    /// Is the app currently registered as a login item?
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enables or disables automatic launch at login.
    /// Returns `false` if the change failed.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                // Already registered? Then do nothing (registering again would throw).
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            NSLog("Cliposaurus: failed to change login item: \(error)")
            return false
        }
    }
}
