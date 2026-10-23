// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.cliposaurus.app", category: "OverlayModel")

/// State and actions of the overlay. A single source of truth accessed by both the
/// `OverlayView` and the global hotkey handlers.
@MainActor
final class OverlayModel: ObservableObject {
    private let modelContext: ModelContext

    @Published var searchText: String = ""
    @Published var selectionIndex: Int = 0
    @Published private(set) var items: [ClipItem] = []
    /// Incremented on every show so the view re-focuses the text field.
    @Published var focusRequest: Int = 0

    /// Whether the overlay is currently visible (for hotkeys that should only apply then).
    var isVisible: Bool = false

    /// Pastes the entry into the clipboard (set by the controller).
    var onPaste: ((ClipItem) -> Void)?
    /// Closes the overlay (set by the controller).
    var onClose: (() -> Void)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Reloads the entries: favorites first, then by date descending, filtered by search.
    ///
    /// SwiftData/`SortDescriptor` cannot sort by `Bool` (it requires NSObject), so we fetch
    /// sorted by date and then move the favorites to the top.
    func reload() {
        let descriptor = FetchDescriptor<ClipItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all: [ClipItem]
        do {
            all = try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch clip items in reload: \(error.localizedDescription)")
            all = []
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [ClipItem]
        if query.isEmpty {
            filtered = all
        } else {
            filtered = all.filter { $0.searchableText.localizedCaseInsensitiveContains(query) }
        }
        // Stable partitioning: favorites (already date-sorted) before the rest.
        items = filtered.filter(\.isFavorite) + filtered.filter { !$0.isFavorite }

        if items.isEmpty {
            selectionIndex = 0
        } else if selectionIndex >= items.count {
            selectionIndex = items.count - 1
        }
    }

    // MARK: - Navigation

    func moveSelection(_ delta: Int) {
        guard !items.isEmpty else { return }
        selectionIndex = min(max(0, selectionIndex + delta), items.count - 1)
    }

    func resetSelection() {
        selectionIndex = 0
    }

    // MARK: - Actions

    /// Pastes the currently selected entry.
    func selectCurrent() {
        guard items.indices.contains(selectionIndex) else { return }
        onPaste?(items[selectionIndex])
    }

    /// Pastes the quick-paste entry (index 0 = entry 1).
    func selectQuickPaste(index: Int) {
        guard isVisible, items.indices.contains(index) else { return }
        onPaste?(items[index])
    }

    /// Toggles the favorite status of the selected entry.
    func toggleFavoriteSelected() {
        guard isVisible, items.indices.contains(selectionIndex) else { return }
        let item = items[selectionIndex]
        item.isFavorite.toggle()
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save favorite status: \(error.localizedDescription)")
        }
        reload()
    }
}
