// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import AppKit
import SwiftUI
import SwiftData
import KeyboardShortcuts

/// Borderless panel that may receive keyboard focus despite having no title bar.
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Manages the global overlay window: showing, positioning, focus, closing.
@MainActor
final class OverlayController: NSObject, NSWindowDelegate {
    let model: OverlayModel
    /// Created lazily on the first show – see `ensurePanel()`. If the panel (including the
    /// SwiftUI `NSHostingView`) were built while still hidden, the list would render no rows
    /// on the very first open (empty list after restart).
    private var panel: OverlayPanel?
    /// The app that was active before opening – regains focus when we close.
    private weak var previousApp: NSRunningApplication?

    init(modelContext: ModelContext) {
        self.model = OverlayModel(modelContext: modelContext)
        super.init()
        model.onClose = { [weak self] in self?.hide() }
    }

    /// Creates the panel on demand (on the first show).
    private func ensurePanel() -> OverlayPanel {
        if let panel { return panel }
        let panel = buildPanel()
        self.panel = panel
        return panel
    }

    private func buildPanel() -> OverlayPanel {
        let panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .modalPanel
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.delegate = self

        let root = OverlayView(model: model)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = panel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        return panel
    }

    // MARK: - Control

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        // Load the data FIRST, then create the panel/SwiftUI content, so the view renders
        // with a populated list from the start (otherwise the first render is empty).
        model.searchText = ""
        model.resetSelection()
        model.reload()
        model.isVisible = true
        model.focusRequest += 1

        let panel = ensurePanel()
        positionPanel(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // Register overlay-scoped shortcuts (Cmd+F, Cmd+1…6) only while the overlay is open
        // so they don't block other apps system-wide.
        KeyboardShortcuts.enable(KeyboardShortcuts.Name.overlayScoped)
    }

    /// Closes the overlay and returns focus to the previously active app.
    ///
    /// Instead of bringing the other app forward via `activate()` (which macOS 14+ denies via
    /// "cooperative activation"), our app hides itself with `NSApp.hide(nil)` – which it is
    /// always allowed to do, and which returns focus to the previously active app. `completion`
    /// only runs once that app is frontmost again, so a subsequent Cmd+V has a valid target.
    func hide(completion: (() -> Void)? = nil) {
        guard let panel, panel.isVisible else { completion?(); return }
        model.isVisible = false
        KeyboardShortcuts.disable(KeyboardShortcuts.Name.overlayScoped)

        let target = previousApp
        previousApp = nil
        panel.orderOut(nil)
        NSApp.hide(nil)

        if let target {
            waitUntilFrontmost(target, completion: completion)
        } else {
            completion?()
        }
    }

    /// Polls briefly (up to ~0.5 s) until the target app has focus, then runs `completion`.
    private func waitUntilFrontmost(
        _ app: NSRunningApplication,
        remaining: Int = 25,
        completion: (() -> Void)?
    ) {
        let isFront = NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
        if isFront || remaining <= 0 {
            completion?()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.waitUntilFrontmost(app, remaining: remaining - 1, completion: completion)
        }
    }

    /// Centers the panel on the screen that currently contains the mouse pointer.
    private func positionPanel(_ panel: OverlayPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }

        let size = panel.frame.size
        let x = visible.midX - size.width / 2
        // Place it slightly above the center, spotlight-style.
        let y = visible.midY - size.height / 2 + visible.height * 0.08
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - NSWindowDelegate

    /// Click outside the overlay or switch to another app → close.
    func windowDidResignKey(_ notification: Notification) {
        if model.isVisible {
            hide()
        }
    }
}
