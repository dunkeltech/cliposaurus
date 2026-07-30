// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import KeyboardShortcuts

/// Central definition of all customizable global hotkeys with their defaults.
extension KeyboardShortcuts.Name {
    /// Show/hide the overlay – default: Cmd+Shift+C.
    static let toggleOverlay = Self("toggleOverlay", default: .init(.c, modifiers: [.command, .shift]))

    /// Toggle the selected entry as a favorite – default: Cmd+F.
    static let toggleFavorite = Self("toggleFavorite", default: .init(.f, modifiers: [.command]))

    // Quick paste 1–6 – default: Cmd+1 … Cmd+6.
    static let quickPaste1 = Self("quickPaste1", default: .init(.one, modifiers: [.command]))
    static let quickPaste2 = Self("quickPaste2", default: .init(.two, modifiers: [.command]))
    static let quickPaste3 = Self("quickPaste3", default: .init(.three, modifiers: [.command]))
    static let quickPaste4 = Self("quickPaste4", default: .init(.four, modifiers: [.command]))
    static let quickPaste5 = Self("quickPaste5", default: .init(.five, modifiers: [.command]))
    static let quickPaste6 = Self("quickPaste6", default: .init(.six, modifiers: [.command]))

    /// All quick-paste names in order (index 0 → entry 1).
    static var quickPasteAll: [KeyboardShortcuts.Name] {
        [quickPaste1, quickPaste2, quickPaste3, quickPaste4, quickPaste5, quickPaste6]
    }

    /// Shortcuts that may only be active while the overlay is open. Otherwise they would,
    /// e.g., intercept `Cmd+F` system-wide and break Find in other apps.
    static var overlayScoped: [KeyboardShortcuts.Name] {
        [toggleFavorite] + quickPasteAll
    }
}
