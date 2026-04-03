# CleanLock App

Menu bar app for [CleanLock](https://github.com/ugurcandede/cleanlock) — temporarily disable keyboard and trackpad while cleaning your Mac.

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

## Build & Run

Requires Swift 5.9+ and the [cleanlock](https://github.com/ugurcandede/cleanlock) repo cloned alongside this project.

```
Desktop/Projects/
├── cleanlock/        # CLI + CleanLockCore library
└── cleanlock-app/    # This repo
```

```bash
swift build
swift run
```

## Permissions

CleanLock App requires **Accessibility** permission to block input. The app will prompt you to grant this on first launch.

## Architecture

This app depends on `CleanLockCore` from the cleanlock package:

- **CleanLockSession** — session orchestration (start/cancel/onEnd)
- **InputBlocker** — CGEvent tap for input blocking
- **BrightnessControl** — screen brightness dimming
- **CountdownWindow** — full-screen overlay with countdown

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel

## License

MIT
