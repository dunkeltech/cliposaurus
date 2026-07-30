// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import SwiftUI
import KeyboardShortcuts

/// Settings window: customize hotkeys and set the history size.
struct SettingsView: View {
    @AppStorage("maxItems") private var maxItems: Int = 50
    @AppStorage("autoPaste") private var autoPaste: Bool = true
    /// Updated on appear to show the permission status.
    @State private var accessibilityTrusted: Bool = Paster.isTrusted
    /// Mirrors the login-item status (SMAppService).
    @State private var launchAtLogin: Bool = LoginItem.isEnabled

    var body: some View {
        TabView {
            hotkeysTab
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 460)
        .padding()
    }

    // MARK: - Hotkeys

    private var hotkeysTab: some View {
        Form {
            Section("Overlay") {
                KeyboardShortcuts.Recorder(String(localized: "Open / Close:"), name: .toggleOverlay)
            }
            Section("In the overlay") {
                KeyboardShortcuts.Recorder(String(localized: "Mark as favorite:"), name: .toggleFavorite)
            }
            Section("Quick paste") {
                ForEach(Array(KeyboardShortcuts.Name.quickPasteAll.enumerated()), id: \.offset) { index, name in
                    KeyboardShortcuts.Recorder(String(localized: "Entry \(index + 1):"), name: name)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch Cliposaurus at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if !LoginItem.setEnabled(newValue) {
                            // On failure, reset the toggle to the real status.
                            launchAtLogin = LoginItem.isEnabled
                        }
                    }
            }

            Section("History") {
                Stepper(value: $maxItems, in: 10...500, step: 10) {
                    Text("Maximum number of entries: \(maxItems)")
                }
                Text("Favorites don't count toward the limit and are never deleted automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Pasting") {
                Toggle("Paste automatically after selection", isOn: $autoPaste)
                Text("Automatically sends ⌘V to the active app after selection. Otherwise the entry is only copied and you paste it yourself with ⌘V.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if autoPaste && !accessibilityTrusted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Accessibility permission required.")
                            .font(.footnote)
                        Spacer()
                        Button("Grant…") {
                            Paster.requestPermission()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            accessibilityTrusted = Paster.isTrusted
            launchAtLogin = LoginItem.isEnabled
        }
    }
}
