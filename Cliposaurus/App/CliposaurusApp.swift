// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import SwiftUI

@main
struct CliposaurusApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        // Menu bar icon with a dropdown menu (no Dock icon thanks to LSUIElement).
        MenuBarExtra("Cliposaurus", image: "MenuBarIcon") {
            MenuBarContent(coordinator: coordinator)
        }
        .menuBarExtraStyle(.menu)

        // Settings window (opens via "Settings…" / Cmd+,).
        Settings {
            SettingsView()
        }
    }
}
