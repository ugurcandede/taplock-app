---
layout: default
title: Guide
---

# Usage Guide

## CLI

### Basic Usage

```bash
taplock                    # Lock until cancelled (5 min safety auto-unlock)
taplock 30                 # Lock for 30 seconds
taplock 2m                 # Lock for 2 minutes
taplock 1m30s              # Lock for 1 minute 30 seconds
```

### Options

| Option | Description |
|---|---|
| `--cancel` | Cancel an active lock session (from another terminal) |
| `--keyboard-only` | Block keyboard only, not trackpad |
| `--no-overlay` | Skip the full-screen overlay UI |
| `--delay <seconds>` | Wait before activating lock |
| `--color <value>` | Overlay color: name (`black`, `red`, `blue`...) or hex (`fff`, `#FF0000`) |
| `--dim` | Reduce screen brightness to minimum during lock |
| `--silent` | Disable sound effects |
| `-h, --help` | Show help |
| `-v, --version` | Show version |

### Examples

```bash
# Clean your screen with a pure black background
taplock --color black --dim --silent

# Lock keyboard only with a 5 second delay
taplock 2m --keyboard-only --delay 5

# Cancel an active session from another terminal
taplock --cancel
```

---

## Menu Bar App

### Starting a Session

1. Click the **lock icon** in the menu bar
2. Enter duration in seconds, or toggle **indefinite** mode
3. Optionally use a **preset** (30s, 1m, 2m, 5m, 10m) to fill the input
4. Click **start**

### Settings

Expand the **settings** panel to configure:

- **Keyboard only** — block keyboard only, trackpad stays active
- **Show overlay** — toggle the full-screen countdown
- **Dim screen** — reduce brightness to minimum
- **Silent** — disable start/end sounds
- **Show timer in menu bar** — display countdown next to the lock icon
- **Delay** — seconds to wait before lock activates
- **Color** — overlay background color presets

### Cancelling

- Click the lock icon during a session and press **cancel**
- Or hold **Cmd+Option+Ctrl+L** for 3 seconds (emergency cancel)

---

## Accessibility Permission

TapLock uses a CGEvent tap to intercept keyboard and trackpad events. This requires **Accessibility** permission.

### First Run

1. TapLock will prompt you to grant permission
2. System Settings opens automatically
3. Toggle TapLock **on** in Privacy & Security > Accessibility
4. Return to TapLock — it will detect the permission

### If Permission is Missing

- **CLI**: The app prints a message and waits up to 30 seconds
- **App**: A warning banner appears with a **Grant** button

---

## Emergency Cancel

At any time during a lock session, hold **Cmd + Option + Ctrl + L** for **3 seconds** to immediately cancel the lock. This works even when all input is blocked — modifier keys are always detected.
