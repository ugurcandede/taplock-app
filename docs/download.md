---
layout: default
title: Download
---

# Download

## Homebrew (Recommended)

```bash
brew tap ugurcandede/tap
```

### CLI

```bash
brew install taplock
```

### Menu Bar App

```bash
brew install --cask taplock-app
```

---

## GitHub Releases

Download universal binaries (Apple Silicon + Intel) directly:

- **CLI**: [github.com/ugurcandede/taplock/releases](https://github.com/ugurcandede/taplock/releases)
- **App**: [github.com/ugurcandede/taplock-app/releases](https://github.com/ugurcandede/taplock-app/releases)

---

## Windows

Relax mode has a Windows port — a single executable, no installer:

- **Download**: [TapLock](https://github.com/ugurcandede/taplock-windows/releases/latest/download/TapLock.exe) · [all releases](https://github.com/ugurcandede/taplock-windows/releases)
- **Details**: [the Windows page]({{ '/windows' | relative_url }})

Requires Windows 10 version 1809 or later. The executable is unsigned, so SmartScreen may stop it the first time — choose **More info → Run anyway**. Lock mode is not part of the port.

---

## Build from Source

Requires Swift 5.9+ (Xcode Command Line Tools).

### CLI

```bash
git clone https://github.com/ugurcandede/taplock.git
cd taplock
swift build -c release
# Binary at .build/release/taplock
```

### App

```bash
git clone --recurse-submodules https://github.com/ugurcandede/taplock-app.git
cd taplock-app
swift build -c release
./scripts/bundle.sh .build/release/TapLockApp
open TapLock.app
```

---

## Requirements

- **macOS**: 13.0 (Ventura) or later · Apple Silicon or Intel
- **Windows**: 10 version 1809 (build 17763) or later, 64-bit
