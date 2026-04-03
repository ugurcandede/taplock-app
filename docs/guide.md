---
layout: default
title: Guide
---

# Usage Guide

## CLI

### Lock Mode

```bash
taplock                    # Lock until cancelled (5 min safety auto-unlock)
taplock 30                 # Lock for 30 seconds
taplock 2m                 # Lock for 2 minutes
taplock 1h30m              # Lock for 1 hour 30 minutes
```

#### Lock Options

| Option | Description |
|---|---|
| `--cancel` | Cancel an active lock session |
| `--keyboard-only` | Block keyboard only, not trackpad |
| `--no-overlay` | Skip the full-screen overlay UI |
| `--delay <seconds>` | Wait before activating lock |
| `--color <value>` | Overlay color: name (`black`, `red`...) or hex (`fff`, `#FF0000`) |
| `--dim` | Reduce screen brightness to minimum during lock |
| `--silent` | Disable sound effects |

### Relax Mode

```bash
taplock relax --every 25m --break 5m          # Pomodoro-style breaks
taplock relax --every 1h --break 10m          # Hourly 10-min breaks
taplock relax --every 45m --break 5m --theme minimal --color blue
taplock relax                                  # Start with saved config
taplock relax --config                         # Show saved config
taplock relax --cancel                         # Stop relaxing session
taplock relax --reset                          # Delete saved config
```

#### Relax Options

| Option | Description |
|---|---|
| `--every <duration>` | Interval between breaks (e.g. `25m`, `1h`, `1h30m`) |
| `--break <duration>` | Break duration (e.g. `5m`, `10m`, `30s`) |
| `--theme <name>` | Visual theme: `breathing` (default), `minimal`, `mini` |
| `--color <value>` | Overlay color (default: `green`) |
| `--opacity <0.1-1.0>` | Overlay opacity (default: `0.85`) |
| `--silent` | Disable all sounds including pre-notification |
| `--config` | Show saved configuration |
| `--reset` | Delete saved configuration |

#### Relax Themes

| Theme | Description |
|---|---|
| **breathing** | Full-screen dark overlay with a softly pulsing circle |
| **minimal** | Centered glass card with blur effect, no full-screen background |
| **mini** | Small floating bar at top of screen — non-intrusive |

Configuration is auto-saved when `--every` and `--break` are provided. Run `taplock relax` to start with saved config.

### Examples

```bash
# Full cleaning mode: black screen, dimmed, silent
taplock --color black --dim --silent

# Lock keyboard only with a 5 second delay
taplock 2m --keyboard-only --delay 5

# Cancel an active lock session
taplock --cancel

# Pomodoro with green breathing overlay
taplock relax --every 25m --break 5m --theme breathing --color green

# Hourly break with minimal theme, semi-transparent
taplock relax --every 1h --break 10m --theme minimal --opacity 0.5
```

---

## Menu Bar App

The app has two modes, switchable via the segmented control at the top of the popover.

### Lock Mode

1. Click the **lock icon** in the menu bar
2. Enter duration in seconds, or toggle **indefinite** mode
3. Optionally use a **preset** (30s, 1m, 2m, 5m, 10m) to fill the input
4. Click **start**

#### Lock Settings

- **Keyboard only** — block keyboard only, trackpad stays active
- **Show overlay** — toggle the full-screen countdown
- **Dim screen** — reduce brightness to minimum
- **Silent** — disable start/end sounds
- **Show timer in menu bar** — display countdown next to the lock icon
- **Delay** — seconds to wait before lock activates
- **Color** — overlay background color presets

### Relax Mode

1. Switch to **Relax** mode via the segmented control
2. Enter interval and break duration (with s/m/h unit selector for each)
3. Optionally use a **preset** (25/5, 45/10, 50/10)
4. Click **start**

#### Relax Settings

- **Theme** — breathing, minimal, or mini
- **Color** — overlay accent color
- **Transparency** — overlay transparency level
- **Silent** — disable all sounds
- **Show timer in menu bar** — display countdown next to the leaf icon

The menu bar icon changes to a **leaf** when in relax mode.

### Cancelling

- Click the menu bar icon during a session and press **cancel** / **stop**
- During a break, press **skip** to dismiss and continue the interval
- Or hold **Cmd+Option+Ctrl+L** for 3 seconds (emergency cancel, lock mode only)

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
