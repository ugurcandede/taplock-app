<div align="center">
  <img src="docs/assets/images/icon.png" alt="TapLock" width="80">
  <h1>TapLock App</h1>
  <p>Menu bar app to temporarily disable keyboard and trackpad input on your Mac.</p>
  <br>
  <a href="https://github.com/ugurcandede/taplock-app/releases/latest"><img src="https://img.shields.io/github/v/release/ugurcandede/taplock-app?label=version&style=flat-square" alt="Version"></a>
  <a href="https://github.com/ugurcandede/taplock-app/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/ugurcandede/taplock-app/build.yml?style=flat-square" alt="Build"></a>
  <br>
  <img src="https://img.shields.io/badge/macOS-13.0%2B-000?style=flat-square&logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Source%20Available-lightgrey?style=flat-square" alt="License"></a>
</div>

---

## Install

```bash
brew tap ugurcandede/taplock
brew install --cask taplock-app
```

---

## Features

| | Feature |
|---|---|
| 🔒 | Menu bar icon with lock status indicator |
| ⏱️ | Quick presets: 30s, 1m, 2m, 5m, 10m |
| 🔢 | Custom duration input (seconds) |
| ♾️ | Indefinite lock mode (5 min safety auto-unlock) |
| ⏳ | Pre-lock delay with visible countdown |
| ⌨️ | Keyboard only mode |
| 🎨 | Overlay color presets |
| 🔅 | Screen dimming |
| 🔇 | Silent mode |
| 🚨 | Emergency cancel: hold **⌘⌥⌃L** for 3 seconds |

---

## Screenshots

<div align="center">

| Indefinite Mode | Custom Duration | Settings |
|:---:|:---:|:---:|
| <img src="screenshots/app-infinite.png" alt="Indefinite" width="200"> | <img src="screenshots/app-seconds.png" alt="Duration" width="200"> | <img src="screenshots/settings.png" alt="Settings" width="200"> |

**Lock Screen Overlay**

<img src="screenshots/lock-screen.png" alt="Lock Screen" width="600">

</div>

---

## Build from source

Requires Swift 5.9+. Uses [TapLock](https://github.com/ugurcandede/taplock) as a git submodule.

```bash
git clone --recurse-submodules https://github.com/ugurcandede/taplock-app.git
cd taplock-app
swift build -c release
./scripts/bundle.sh .build/release/TapLockApp
open TapLock.app
```

---

## Architecture

Built on `TapLockCore` from the [taplock](https://github.com/ugurcandede/taplock) package:

| Module | Purpose |
|---|---|
| **TapLockSession** | Session orchestration (start/cancel/onEnd) |
| **InputBlocker** | CGEvent tap for input blocking |
| **BrightnessControl** | Screen brightness control |
| **CountdownWindow** | Full-screen overlay with countdown |

---

## Requirements

macOS 13.0 (Ventura) or later · Apple Silicon or Intel · Accessibility permission

## Links

[Website](https://ugurcandede.github.io/taplock-app) · [CLI Repo](https://github.com/ugurcandede/taplock) · [Guide](https://ugurcandede.github.io/taplock-app/guide) · [FAQ](https://ugurcandede.github.io/taplock-app/faq)

## License

Source Available — free to use, not to modify or redistribute. See [LICENSE](LICENSE).
