// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Jan Gehring
//
// This file is part of Cliposaurus. See the LICENSE file for details.

import AppKit
import CryptoKit

/// Wraps reading from and writing to `NSPasteboard.general`.
enum PasteboardService {

    /// Stable hash over an entry's content for duplicate detection.
    static func hash(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func hash(for string: String) -> String {
        hash(for: Data(string.utf8))
    }

    /// Writes a `ClipItem` back to the native clipboard so it behaves as if freshly
    /// copied and can be pasted with `Cmd+V`.
    ///
    /// Returns the pasteboard's `changeCount` after writing, so the monitor can ignore
    /// the change it triggered itself.
    @discardableResult
    static func write(_ item: ClipItem) -> Int {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.kind {
        case .text:
            if let text = item.text {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData, let image = NSImage(data: data) {
                pb.writeObjects([image])
            }
        case .file:
            if let s = item.fileURLString, let url = URL(string: s) {
                pb.writeObjects([url as NSURL])
            }
        }
        return pb.changeCount
    }
}
