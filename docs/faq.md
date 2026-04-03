---
layout: default
title: FAQ
---

# Frequently Asked Questions

### Why does TapLock need Accessibility permission?

TapLock uses a `CGEvent` tap to intercept and block keyboard, trackpad, and mouse events at the system level. macOS requires Accessibility permission for any app that monitors or modifies input events. TapLock does not log, record, or transmit any input data.

---

### Is my input data collected or sent anywhere?

No. TapLock blocks events locally and discards them. No keystrokes, mouse movements, or any other data is recorded or transmitted.

---

### Why is the cursor still visible during lock?

The cursor remains visible but non-functional — all clicks and movements are blocked by the CGEvent tap. Hiding the cursor caused restoration issues on some macOS versions, so we chose reliability over aesthetics.

---

### Do 3-finger gestures still work?

TapLock blocks gesture events (types 29/30/31), but macOS processes some multi-finger gestures at a lower level before they become CGEvents. Some system gestures like Mission Control may still trigger.

---

### Does it support multiple monitors?

Currently, the overlay is displayed on the main screen only. Multi-monitor support is planned for a future release. Input blocking works system-wide regardless of which screen is active.

---

### What happens if I revoke Accessibility permission during a lock?

The CGEvent tap will stop receiving events, effectively ending the lock. The overlay will remain until the session timer expires. We recommend not changing permissions during an active session.

---

### Can I run both CLI and App at the same time?

They share the same `TapLockCore` library but run as separate processes. Only one lock session can be active at a time — the CLI uses a PID file to prevent multiple instances.

---

### How do I uninstall?

```bash
# CLI
brew uninstall taplock

# App
brew uninstall --cask taplock-app

# Or manually delete TapLock.app from Applications
```

Then remove TapLock from System Settings > Privacy & Security > Accessibility.

---

### Build fails with "no such module 'Testing'"

The test suite uses Swift Testing framework, which requires Xcode (not just Command Line Tools). Tests run in CI where Xcode is available. You can still build without running tests:

```bash
swift build -c release
```

---

### Build fails with "swift-tools-version 6.0"

You need Swift 6.0+. Check your version:

```bash
swift --version
```

Update via Xcode or install the latest Swift toolchain from [swift.org](https://www.swift.org/install/).
