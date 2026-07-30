# Cliposaurus 🦕

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey.svg)

A lightweight clipboard manager for macOS – it lives in the menu bar, brings up a searchable
overlay via a global hotkey, and writes the selected entry back to the native clipboard.

## Features (v1)

- **Menu bar app** without a Dock icon (`LSUIElement`)
- **History** for text, images and files (SwiftData, configurable limit)
- **Global overlay** (`Cmd+Shift+C`) with instant text focus, live search, arrow-key navigation, `Esc` to close
- **Favorites** (`Cmd+F`) – pinned to the top permanently, marked with a star
- **Quick paste** `Cmd+1…6` for the first six entries
- **Automatic paste** via `Enter` / click / quick paste → the entry lands in `NSPasteboard` and is pasted straight into the target app via a simulated `⌘V` (can be disabled; requires Accessibility permission)
- **Settings** to customize all hotkeys, the history size and the auto-paste behavior
- **Localized** UI (English base + German) that follows the system language

## Requirements

- macOS 14+ (Sonoma) – required for SwiftData
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & run

```bash
./scripts/build.sh          # generates the project and builds it
open build/Build/Products/Debug/Cliposaurus.app
```

The icon then appears in the menu bar. Press `Cmd+Shift+C` to open the overlay.

> **Note (Nix/devenv):** If a Nix devenv is active in your shell, it overrides `DEVELOPER_DIR`,
> `SDKROOT`, `LD` etc. and hijacks Xcode's linker. `scripts/build.sh` strips these variables
> before invoking `xcodebuild`. A direct `xcodebuild` fails with `ld: unknown options` in such
> a shell.

## Project structure

```
Cliposaurus/
├── App/         CliposaurusApp (scenes), AppCoordinator (wiring)
├── MenuBar/     menu bar dropdown
├── Models/      ClipItem (SwiftData @Model)
├── Overlay/     OverlayController (NSPanel) + OverlayModel + OverlayView
├── Services/    ClipboardMonitor, PasteboardService, Shortcuts (hotkey defaults)
└── Settings/    SettingsView (hotkey recorder, history size)
```

## Icons

The app and menu bar icons show a dinosaur logo. The source SVGs are rasterized with
`rsvg-convert` into the PNGs under `Cliposaurus/Assets.xcassets/` (the app icon in color, the
menu bar icon as a monochrome template for light/dark mode).

## Known limitations / roadmap

- No app signing/notarization (dev build, ad-hoc signed)

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md) first.

> **Important:** By opening a pull request you agree to the
> [Contributor License Agreement](CLA.md). It keeps your contributions under the GPLv3 **and**
> grants the project maintainer the right to also distribute the code under other licenses
> (see *License*).

## License

Cliposaurus is licensed under the **GNU General Public License v3.0** – see [LICENSE](LICENSE).
This means anyone who distributes the app or builds on it must also release their version's
source under the GPLv3. Cliposaurus therefore stays open source permanently.

### Dual licensing

The maintainer (**Jan Gehring**) is the sole copyright holder (secured via the [CLA](CLA.md))
and additionally offers Cliposaurus under a **commercial license**. This specifically allows:

- distributing signed binaries via the **Mac App Store** (whose DRM/terms are incompatible with
  the GPL), and
- developing **proprietary (closed-source) extensions**.

As the copyright holder, the maintainer is not bound by their own GPLv3. For third parties only
the GPLv3 applies, unless a separate commercial license has been obtained. For commercial
licensing inquiries: <jan.gehring@gmail.com>.

The third-party library [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
used here is under the MIT license (GPL-compatible).
