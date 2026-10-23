// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import AppKit
import SwiftData
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.cliposaurus.app", category: "ClipboardMonitor")

/// Watches the system clipboard by polling and stores new entries in SwiftData.
///
/// macOS provides no change event for the pasteboard, so `changeCount` is polled at short
/// intervals – the established pattern for clipboard histories.
@MainActor
final class ClipboardMonitor {
    private let modelContext: ModelContext
    private var timer: Timer?
    private var lastChangeCount: Int
    /// A changeCount we produced ourselves by writing back – it is ignored.
    private var ignoreChangeCount: Int = -1

    /// Configurable limit for non-favorite entries.
    var maxItems: Int {
        get { UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 50 }
        set { UserDefaults.standard.set(newValue, forKey: "maxItems") }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Remembers a changeCount that resulted from our own write-back.
    func markSelfCopy(changeCount: Int) {
        ignoreChangeCount = changeCount
        lastChangeCount = changeCount
    }

    private func poll() {
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        // Don't store a change we triggered ourselves.
        if current == ignoreChangeCount { return }

        guard let captured = capture(from: pb) else { return }
        insert(captured)
    }

    // MARK: - Capture

    private struct Captured {
        var kind: ClipKind
        var text: String?
        var imageData: Data?
        var fileURLString: String?
        var hash: String
    }

    private func capture(from pb: NSPasteboard) -> Captured? {
        // Order: file URLs > image > text.
        if let urls = pb.readObjects(forClasses: [NSURL.self]) as? [URL], let url = urls.first,
           url.isFileURL {
            let s = url.absoluteString
            return Captured(kind: .file, text: nil, imageData: nil,
                            fileURLString: s, hash: PasteboardService.hash(for: s))
        }

        if let images = pb.readObjects(forClasses: [NSImage.self]) as? [NSImage],
           let image = images.first,
           let png = image.pngData() {
            return Captured(kind: .image, text: nil, imageData: png,
                            fileURLString: nil, hash: PasteboardService.hash(for: png))
        }

        if let string = pb.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Captured(kind: .text, text: string, imageData: nil,
                            fileURLString: nil, hash: PasteboardService.hash(for: string))
        }

        return nil
    }

    // MARK: - Persistence

    private func insert(_ captured: Captured) {
        let hash = captured.hash

        // Duplicate? Move the existing entry to the top instead of adding a new one.
        var descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { $0.contentHash == hash }
        )
        descriptor.fetchLimit = 1
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                existing.createdAt = .now
                try modelContext.save()
                return
            }
        } catch {
            logger.error("Failed to check duplicate or update existing item: \(error.localizedDescription)")
        }

        let item = ClipItem(
            kind: captured.kind,
            text: captured.text,
            imageData: captured.imageData,
            fileURLString: captured.fileURLString,
            contentHash: hash
        )
        modelContext.insert(item)
        enforceLimit()
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save new clip item: \(error.localizedDescription)")
        }
    }

    /// Deletes the oldest non-favorite entries when the limit is exceeded.
    private func enforceLimit() {
        let limit = max(1, maxItems)
        let descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { $0.isFavorite == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let nonFavorites = try modelContext.fetch(descriptor)
            guard nonFavorites.count > limit else { return }
            for item in nonFavorites[limit...] {
                modelContext.delete(item)
            }
        } catch {
            logger.error("Failed to fetch non-favorites during enforceLimit: \(error.localizedDescription)")
        }
    }
}

extension NSImage {
    /// PNG representation of the image (for storage and write-back).
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
