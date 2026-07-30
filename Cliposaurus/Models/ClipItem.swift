// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import Foundation
import SwiftData
import AppKit

/// Type of a stored clipboard entry.
enum ClipKind: Int, Codable {
    case text
    case image
    case file
}

/// A single entry in the clipboard history.
///
/// Depending on `kind`, a `ClipItem` holds exactly one payload:
/// - `.text`  → `text`
/// - `.image` → `imageData` (PNG)
/// - `.file`  → `fileURLString`
@Model
final class ClipItem {
    /// Stable identifier (useful for quick paste / selection).
    @Attribute(.unique) var id: UUID
    /// Time of the last copy. Updated on duplicates (→ moves back to the top).
    var createdAt: Date
    /// Favorite? Favorites are pinned to the very top permanently.
    var isFavorite: Bool
    /// Raw enum value for `ClipKind` (SwiftData stores the Int).
    var kindRaw: Int

    var text: String?
    @Attribute(.externalStorage) var imageData: Data?
    var fileURLString: String?

    /// Hash of the content for fast duplicate detection.
    var contentHash: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        isFavorite: Bool = false,
        kind: ClipKind,
        text: String? = nil,
        imageData: Data? = nil,
        fileURLString: String? = nil,
        contentHash: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.kindRaw = kind.rawValue
        self.text = text
        self.imageData = imageData
        self.fileURLString = fileURLString
        self.contentHash = contentHash
    }

    var kind: ClipKind {
        get { ClipKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    /// Short, single-line display text for the list and search.
    var preview: String {
        switch kind {
        case .text:
            let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.replacingOccurrences(of: "\n", with: " ")
        case .image:
            return String(localized: "🖼 Image")
        case .file:
            if let s = fileURLString, let url = URL(string: s) {
                return "📄 " + url.lastPathComponent
            }
            return String(localized: "📄 File")
        }
    }

    /// Text the search filters over.
    var searchableText: String {
        switch kind {
        case .text: return text ?? ""
        case .image: return "bild image"
        case .file:
            guard let s = fileURLString, let url = URL(string: s) else { return "datei file" }
            return url.lastPathComponent + " " + url.path
        }
    }
}
