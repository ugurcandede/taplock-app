<div align="center">
  <img src="docs/assets/images/icon.png" alt="TapLock" width="80">
  <h1>TapLock App</h1>
  <p>Menu bar app to temporarily disable keyboard and trackpad input, or take relaxing breaks on your Mac.</p>
  <br>
  <a href="https://github.com/ugurcandede/taplock-app/releases/latest"><img src="https://img.shields.io/github/v/release/ugurcandede/taplock-app?label=version&style=flat-square" alt="Version"></a>
  <a href="https://github.com/ugurcandede/taplock-app/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/ugurcandede/taplock-app/build.yml?style=flat-square" alt="Build"></a>
  <br>
  <img src="https://img.shields.io/badge/macOS-13.0%2B-000?style=flat-square&logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Source%20Available-lightgrey?style=flat-square" alt="License"></a>
</div>

---
#### Releated
<p style="text-align: center">
  <a href="https://ugurcandede.github.io/taplock-app"><img src="https://img.shields.io/badge/Website-000?style=flat-square&logo=safari&logoColor=white" alt="Website"></a>
  <a href="https://github.com/ugurcandede/taplock"><img src="https://img.shields.io/badge/CLI%20Repo-000?style=flat-square&logo=github&logoColor=white" alt="CLI"></a>
  <a href="https://github.com/ugurcandede/homebrew-taplock"><img src="https://img.shields.io/badge/Homebrew%20Tap-FBB040?style=flat-square&logo=homebrew&logoColor=000" alt="Homebrew"></a>
</p>

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
| 🔒 | **Lock Mode** — Menu bar icon with lock status indicator |
| ⏱️ | Quick presets: 30s, 1m, 2m, 5m, 10m |
| 🔢 | Custom duration input (seconds, minutes, hours) |
| ♾️ | Indefinite lock mode (5 min safety auto-unlock) |
| ⏳ | Pre-lock delay with visible countdown |
| ⌨️ | Keyboard only mode |
| 🧘 | **Relax Mode** — Periodic break reminders with calming overlays |
| 🎨 | Overlay color and transparency presets |
| 🔅 | Screen dimming |
| 🔇 | Silent mode |
| 🚨 | Emergency cancel: hold **⌘⌥⌃L** for 3 seconds |

---

## Lock Mode

<div align="center">

| Indefinite Mode | Custom Duration | Settings |
|:---:|:---:|:---:|
| <img src="screenshots/app-infinite.png" alt="Indefinite" width="200"> | <img src="screenshots/app-seconds.png" alt="Duration" width="200"> | <img src="screenshots/settings.png" alt="Settings" width="200"> |

**Lock Screen Overlay**

<img src="screenshots/lock-screen.png" alt="Lock Screen" width="600">

</div>

---

## Relax Mode

<div align="center">

|                             Relax Setup                             |                                   Break Countdown                                    | Break Relaxing Countdown                                                                       |                               Relax Settings                                |
|:-------------------------------------------------------------------:|:------------------------------------------------------------------------------------:|------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------:|
| <img src="screenshots/relax/app.png" alt="Relax Setup" width="200"> | <img src="screenshots/relax/in-app-countdown.png" alt="Break Countdown" width="200"> | <img src="screenshots/relax/in-app-countdown-2.png" alt="Break Session Countdown" width="200"> | <img src="screenshots/relax/settings.png" alt="Relax Settings" width="200"> |

**Overlay Themes**

| Minimal | Mini |
|:---:|:---:|
| <img src="screenshots/relax/minimal.png" alt="Minimal" width="300"> | <img src="screenshots/relax/mini.png" alt="Mini" width="300"> |

| Breathing | Breathing (dark) |
|:---:|:---:|
| <img src="screenshots/relax/breathing.png" alt="Breathing" width="300"> | <img src="screenshots/relax/breathing-2.png" alt="Breathing Dark" width="300"> |

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
| **TapLockSession** | Lock session orchestration (start/cancel/onEnd) |
| **RelaxingSession** | Relaxing session with interval timer and break lifecycle |
| **InputBlocker** | CGEvent tap for input blocking |
| **BrightnessControl** | Screen brightness control |
| **CountdownWindow** | Full-screen lock overlay with countdown |
| **RelaxingWindow** | Relaxing overlay with breathing/minimal/mini themes |
| **ConfigStore** | JSON persistence for relaxing session config |

---

## Requirements

macOS 13.0 (Ventura) or later · Apple Silicon or Intel · Accessibility permission

## License

Source Available — free to use, not to modify or redistribute. See [LICENSE](LICENSE).
