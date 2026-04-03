---
layout: default
title: Home
---

<div style="text-align: center; padding: 40px 0 20px;">
  <h1 style="font-size: 2.5em; margin-bottom: 0.2em;">TapLock</h1>
  <p style="font-size: 1.2em; opacity: 0.7;">Temporarily disable keyboard and trackpad input on your Mac</p>
</div>

<div style="text-align: center; margin: 20px 0 40px;">

```bash
brew tap ugurcandede/taplock
brew install taplock              # CLI
brew install --cask taplock-app   # Menu bar app
```

</div>

---

## Features

| Feature | Description |
|---|---|
| **Input Blocking** | Block keyboard, trackpad, and mouse via CGEvent tap |
| **Countdown Overlay** | Full-screen timer with clock display |
| **Custom Duration** | Seconds, minutes, or indefinite with 5 min safety |
| **Screen Dimming** | Reduce brightness to minimum during lock |
| **Sound Effects** | Audio feedback on lock start/end |
| **Custom Colors** | Named colors or hex values for overlay background |
| **Emergency Cancel** | Hold **Cmd+Option+Ctrl+L** for 3 seconds |
| **Menu Bar App** | Native macOS popover with presets and settings |

---

## Screenshots

<div style="display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; margin: 30px 0;">
  <img src="assets/images/app-infinite.png" alt="Indefinite Mode" width="220">
  <img src="assets/images/app-seconds.png" alt="Custom Duration" width="220">
  <img src="assets/images/settings.png" alt="Settings" width="220">
</div>

**Lock Screen Overlay**

<div style="text-align: center; margin: 20px 0;">
  <img src="assets/images/lock-screen.png" alt="Lock Screen" width="600">
</div>

---

## Quick Start

### CLI

```bash
taplock                          # Lock until cancelled (5 min safety)
taplock 30                       # Lock for 30 seconds
taplock 2m                       # Lock for 2 minutes
taplock --color black --dim      # Full cleaning mode
taplock --cancel                 # Cancel from another terminal
```

### Menu Bar App

1. Launch TapLock from Applications
2. Click the lock icon in the menu bar
3. Set duration or use a preset
4. Click **start**

---

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel
- Accessibility permission (guided setup on first run)

---

<div style="text-align: center; opacity: 0.5; padding: 20px 0;">
  <p>Built with ❤️ for 💻 users</p>
  <p><a href="https://github.com/ugurcandede">ugurcandede</a> · <a href="https://github.com/ugurcandede/taplock">CLI Repo</a> · <a href="https://github.com/ugurcandede/taplock-app">App Repo</a></p>
</div>
