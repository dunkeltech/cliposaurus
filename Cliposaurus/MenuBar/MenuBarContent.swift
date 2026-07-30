// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import SwiftUI
import AppKit

/// Contents of the menu bar dropdown.
struct MenuBarContent: View {
    let coordinator: AppCoordinator
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Open Cliposaurus") {
            coordinator.showOverlay()
        }
        .keyboardShortcut("c", modifiers: [.command, .shift])

        Divider()

        Button("Settings…") {
            openSettings()
            // As an agent app (LSUIElement) the window would otherwise open in the
            // background – activate the app and bring the settings window to the front.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSApp.activate(ignoringOtherApps: true)
                let settingsWindow = NSApp.windows.first {
                    !($0 is OverlayPanel) && $0.styleMask.contains(.titled)
                }
                settingsWindow?.makeKeyAndOrderFront(nil)
                settingsWindow?.orderFrontRegardless()
            }
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("About Cliposaurus") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }

        Divider()

        Button("Quit Cliposaurus") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
