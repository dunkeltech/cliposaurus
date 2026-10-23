// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import SwiftUI
import SwiftData
import KeyboardShortcuts
import OSLog

private let logger = Logger(subsystem: "com.cliposaurus.app", category: "AppCoordinator")

/// Central wiring: SwiftData container, clipboard monitor, overlay and global hotkeys.
@MainActor
final class AppCoordinator: ObservableObject {
    let container: ModelContainer
    private let monitor: ClipboardMonitor
    private let overlay: OverlayController

    init() {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let bundleID = Bundle.main.bundleIdentifier ?? "com.cliposaurus.app"
            let appDir = appSupport.appendingPathComponent(bundleID, isDirectory: true)
            try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

            let storeURL = appDir.appendingPathComponent("Cliposaurus.store")
            let configuration = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: ClipItem.self, configurations: configuration)
            logger.info("SwiftData initialized with store at: \(storeURL.path)")
        } catch {
            logger.critical("Failed to create SwiftData container: \(error.localizedDescription)")
            fatalError("Failed to create SwiftData container: \(error)")
        }

        let context = container.mainContext
        monitor = ClipboardMonitor(modelContext: context)
        overlay = OverlayController(modelContext: context)

        wirePaste()
        registerHotkeys()
        monitor.start()
    }

    /// Whether `Cmd+V` is sent to the target app automatically after selection.
    private var autoPasteEnabled: Bool {
        UserDefaults.standard.object(forKey: "autoPaste") as? Bool ?? true
    }

    /// Connects the overlay's paste action with the pasteboard + monitor.
    private func wirePaste() {
        overlay.model.onPaste = { [weak self] item in
            guard let self else { return }
            let changeCount = PasteboardService.write(item)
            // Mark our own change so the monitor doesn't store it again.
            self.monitor.markSelfCopy(changeCount: changeCount)

            let shouldPaste = self.autoPasteEnabled
            // First close + return focus, then (once the target app is frontmost again)
            // simulate Cmd+V.
            self.overlay.hide {
                guard shouldPaste else { return }
                // Small buffer until the target app's key window is ready.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    Paster.paste()
                }
            }
        }
    }

    /// Opens the overlay (e.g. from the menu).
    func showOverlay() {
        overlay.show()
    }

    private func registerHotkeys() {
        KeyboardShortcuts.onKeyUp(for: .toggleOverlay) { [weak self] in
            self?.overlay.toggle()
        }
        KeyboardShortcuts.onKeyUp(for: .toggleFavorite) { [weak self] in
            self?.overlay.model.toggleFavoriteSelected()
        }
        for (index, name) in KeyboardShortcuts.Name.quickPasteAll.enumerated() {
            KeyboardShortcuts.onKeyUp(for: name) { [weak self] in
                self?.overlay.model.selectQuickPaste(index: index)
            }
        }

        // Disabled by default – only active while the overlay is open (see OverlayController),
        // so Cmd+F & Cmd+1…6 don't permanently block other apps.
        KeyboardShortcuts.disable(KeyboardShortcuts.Name.overlayScoped)
    }
}
