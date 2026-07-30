# Contributing to Cliposaurus

Thanks for your interest in contributing to Cliposaurus! 🦕

## Contributor License Agreement (CLA)

Cliposaurus is released under a [dual-licensing model](README.md#license) (GPLv3 for the public
+ a commercial license offered by the maintainer). For this to work legally, the maintainer must
remain the sole copyright holder.

**By opening a pull request you confirm the [Contributor License Agreement](CLA.md).** In short:
you keep the copyright to your contribution, but grant the maintainer a broad license (including
the right to also distribute your contribution under other licenses). Without this agreement a
contribution unfortunately cannot be merged.

## Development environment

Requirements:

- macOS 14+ (Sonoma)
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

Generate the project, build and run:

```bash
./scripts/build.sh
open build/Build/Products/Debug/Cliposaurus.app
```

`scripts/build.sh` generates the Xcode project from `project.yml` and builds in an environment
sanitized from Nix/devenv (see the note in the [README](README.md#build--run)).

The Xcode project itself (`Cliposaurus.xcodeproj`) is generated and **not** checked in. Just add
new source files under `Cliposaurus/` – XcodeGen picks them up automatically on the next
`xcodegen generate`.

## Code conventions

- Swift, SwiftUI + AppKit; deployment target macOS 14.
- Every new source file starts with the SPDX license header (see existing files):

  ```swift
  // SPDX-License-Identifier: GPL-3.0-or-later
  // Copyright (C) 2026 Jan Gehring
  ```
- Code comments are written in English.
- Match the style of the surrounding files (naming, comment density, idioms).

## Localization

The UI is localized via a String Catalog. **English is the base language** and lives directly in
the code; other languages are translations.

When you add or change user-facing text:

1. **Write the string in English** as a literal. SwiftUI localizes `Text`, `Button`, `Label`,
   `Toggle`, `Section`, `TextField`, etc. automatically. For non-SwiftUI strings (e.g. a
   `KeyboardShortcuts.Recorder` title or a plain `String` such as `ClipItem.preview`), wrap it in
   `String(localized:)` so it is looked up too.
2. **Add the translation** for every supported language in
   [`Cliposaurus/Localizable.xcstrings`](Cliposaurus/Localizable.xcstrings). The key is the exact
   English string. For interpolated integers the key uses `%lld`
   (e.g. `"Maximum number of entries: %lld"`).
3. Currently supported languages: **English (base)** and **German (`de`)**. To add a language,
   add its translations to the catalog and list it under `CFBundleLocalizations` in
   `Cliposaurus/Info.plist`.

Never hard-code a non-English user-facing string in the code.

## Pull requests

1. Fork the repository and create a feature branch.
2. Keep changes focused; one PR per topic.
3. Make sure `./scripts/build.sh` completes without errors.
4. Describe *what* and *why* in the PR – ideally with a screenshot for UI changes.

## Reporting bugs

Use the [issue templates](.github/ISSUE_TEMPLATE). Please include your macOS version, the
Cliposaurus version and reproducible steps.
