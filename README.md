# TapLock App

Menu bar app for [TapLock](https://github.com/ugurcandede/taplock) — temporarily disable keyboard and trackpad while cleaning your Mac.

## Features

- Menu bar icon with lock status indicator
- Quick presets: 30s, 1m, 2m, 5m, 10m
- Custom duration input (seconds)
- Indefinite lock mode (5 min safety auto-unlock)
- Pre-lock delay with visible countdown
- Collapsible settings panel:
  - Keyboard only mode
  - Overlay toggle
  - Screen dimming
  - Silent mode
  - Delay configuration
  - Overlay color presets
- Optional countdown timer in menu bar
- Emergency cancel: hold **Cmd+Option+Ctrl+L** for 3 seconds

## Install

### Homebrew

```bash
brew tap ugurcandede/taplock
brew install --cask taplock-app
```

### Build from source

Requires Swift 5.9+ and the [taplock](https://github.com/ugurcandede/taplock) repo cloned alongside this project.

```
Desktop/Projects/
├── taplock/        # CLI + TapLockCore library
└── taplock-app/    # This repo
```

```bash
swift build -c release
./scripts/bundle.sh .build/release/TapLockApp
open TapLock.app
```

## Permissions

TapLock App requires **Accessibility** permission to block input. The app will prompt you to grant this on first launch.

## Architecture

This app depends on `TapLockCore` from the taplock package:

- **TapLockSession** — session orchestration (start/cancel/onEnd)
- **InputBlocker** — CGEvent tap for input blocking
- **BrightnessControl** — screen brightness dimming
- **CountdownWindow** — full-screen overlay with countdown

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel

## License

Source Available — free to use, not to modify or redistribute. See [LICENSE](LICENSE).
