---
layout: default
title: Download
---

# Download

## Homebrew (Recommended)

```bash
brew tap ugurcandede/taplock
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

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel
