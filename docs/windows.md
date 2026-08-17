---
layout: default
title: Windows
description: TapLock for Windows — periodic break reminders with calming full-screen overlays. A single executable, no installer and no admin rights.
---

<div class="win-hero">
  <span class="win-pill">
    <svg viewBox="0 0 16 16" width="13" height="13" aria-hidden="true"><path fill="currentColor" d="M0 2.25 6.5 1.36v6.3H0zM7.29 1.25 16 0v7.66H7.29zM0 8.34h6.5v6.3L0 13.75zm7.29 0H16V16l-8.71-1.25z"/></svg>
    Windows port
  </span>
  <img src="{{ '/assets/images/icon.png' | relative_url }}" alt="TapLock" class="win-hero-icon">
  <h1>TapLock for Windows</h1>
  <p class="win-lede">Periodic break reminders with calming full-screen overlays.<br>Work for an interval, take a break, repeat.</p>
  <p class="win-lede-strong">Never blocks your input.</p>

  <div class="btn-row">
    <a class="btn btn-primary" href="https://github.com/ugurcandede/taplock-windows/releases/latest/download/TapLock.exe">Download TapLock</a>
    <a class="btn btn-ghost" href="https://github.com/ugurcandede/taplock-windows">View on GitHub</a>
  </div>

  <p class="win-meta">Single file · ~40 MB · Windows 10 1809+ · no installer, no admin rights</p>
</div>

<div class="win-note">
  <div class="win-note-card">
    <h3>🧘 Relax mode, ported</h3>
    <p>The break cycle, the three overlay themes, the posture reminder and the statistics — all of relax mode from the macOS menu bar app, rebuilt for the Windows notification area.</p>
  </div>
  <div class="win-note-card win-note-card--muted">
    <h3>🔒 Lock mode is not here</h3>
    <p>Blocking keyboard and trackpad input on Windows means hooking the input stack. Relax mode never touches it, so this port stays entirely in user space — no keyboard hook, no driver, no elevation.</p>
  </div>
</div>

---

<div class="features">
  <h2>Features</h2>
  <div class="features-grid">
    <div class="feature-card">
      <div class="icon">⏱️</div>
      <h3>Break cycle</h3>
      <p>Work for an interval, break, repeat. Seconds, minutes or hours — or a preset: 25/5, 45/10, 50/10.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🎨</div>
      <h3>Three overlay themes</h3>
      <p>breathing, minimal and mini. Accent colour and transparency are yours, with a five-second preview for each.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🧍</div>
      <h3>Posture reminder</h3>
      <p>A quiet nudge halfway through each interval. Dismissable, and optional.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🔔</div>
      <h3>Sound cues</h3>
      <p>Windows system sounds at the start and end of a break, following your sound scheme. Silent mode available.</p>
    </div>
    <div class="feature-card">
      <div class="icon">📊</div>
      <h3>Statistics</h3>
      <p>Sessions, break time and skip rate — today, by week, month, year, all time or a custom range.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🌗</div>
      <h3>Follows your theme</h3>
      <p>Light and dark, switched live with Windows. The tray glyph tracks the taskbar theme separately.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🚀</div>
      <h3>Launch at login</h3>
      <p>Optional, per-user, no elevation. One registry key under <code>HKCU</code>, removed when you turn it off.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🔄</div>
      <h3>Shared with macOS</h3>
      <p>Config and event log use the same schema as the Mac app, byte for byte. Carry them between machines.</p>
    </div>
    <div class="feature-card">
      <div class="icon">📦</div>
      <h3>One file</h3>
      <p>Ships as a single <code>.exe</code> — nothing to extract, nothing to install, nothing left behind but its config.</p>
    </div>
  </div>
</div>

---

<div class="screenshots">
  <h2>Overlay Themes</h2>
  <img src="{{ '/assets/images/windows/breathing.png' | relative_url }}" alt="Breathing theme" class="screenshot-full" width="720">
  <p class="screenshot-label">breathing — full-screen wash with a softly pulsing disc, on every display</p>
  <div class="screenshots-row screenshots-row--lg" style="margin-top: 40px;">
    <img src="{{ '/assets/images/windows/minimal.png' | relative_url }}" alt="Minimal theme">
    <img src="{{ '/assets/images/windows/posture.png' | relative_url }}" alt="Posture reminder">
  </div>
  <div class="screenshots-row screenshots-row--lg">
    <img src="{{ '/assets/images/windows/mini.png' | relative_url }}" alt="Mini theme">
  </div>
  <p class="screenshot-label">minimal — a glass card over a blurred backdrop · the posture reminder · mini — a bar that never takes focus</p>
</div>

---

<div class="screenshots">
  <h2>The Panel</h2>
  <div class="screenshots-row screenshots-row--top">
    <img src="{{ '/assets/images/windows/panel.png' | relative_url }}" alt="Panel" width="220">
    <img src="{{ '/assets/images/windows/settings.png' | relative_url }}" alt="Settings" width="220">
    <img src="{{ '/assets/images/windows/stats.png' | relative_url }}" alt="Statistics summary" width="220">
  </div>
  <p class="screenshot-label" style="margin-bottom: 40px;">Click the tray icon to open it. The icon fills in and turns green while a session runs, and its tooltip carries the countdown.</p>
  <img src="{{ '/assets/images/windows/statistics.png' | relative_url }}" alt="Statistics window" class="screenshot-full" width="540">
  <p class="screenshot-label">The full statistics window</p>
</div>

---

## Install

Download **[`TapLock`](https://github.com/ugurcandede/taplock-windows/releases/latest/download/TapLock.exe)** and run it. There is nothing to extract and nothing to install.

The executable is unsigned, so SmartScreen may stop it the first time — choose **More info → Run anyway**.

The app has no main window: it lives in the notification area. Click the tray icon to open the panel, enter an interval and a break length, and press **start**. Turn on **launch at login** from settings if you want it back after a reboot.

During a break, **Skip** or <kbd>Esc</kbd> dismisses the overlay and restarts the interval. The mini theme has no <kbd>Esc</kbd> — it never takes focus, so it cannot steal your caret mid-sentence; use its close button instead.

### From source

Requires Python 3.14. Runtime dependencies are PySide6 and Pillow.

```bash
git clone https://github.com/ugurcandede/taplock-windows.git
cd taplock-windows
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

---

## Shared with the Mac app

Both builds read and write the same two files, with the same schema:

```
%APPDATA%\taplock\relax-config.json    settings
%APPDATA%\taplock\events.jsonl         append-only event log
```

On macOS they live in `~/Library/Application Support/taplock/`. Copy either one across and it is understood on the other side — including the `lock_completed` records this build has no use for, which are preserved rather than dropped.

---

## Differences from macOS

Where the port does not match the original, it is on purpose:

| Area | How the port differs |
|---|---|
| **Tray icon** | Windows cannot show text next to a tray icon, so the countdown lives in the tooltip |
| **mini theme** | Never takes focus, so it has no <kbd>Esc</kbd> |
| **breathing theme** | Covers every display; the glass themes open only where the cursor is |
| **Sounds** | Two per cycle, not three — the chime ten seconds before a break is gone |
| **Settings** | Saved on every change, not only when a session starts |
| **Week boundary** | Monday (ISO 8601); macOS follows the system calendar |

---

## Requirements

**Windows 10 version 1809 (build 17763) or later, 64-bit.** The floor comes from Qt and CPython, not from the app; it checks at startup and says so plainly rather than failing deeper in.

No administrator rights, at install or at run.

Leaf and figure icons from [Icons8](https://icons8.com).

<div class="win-cta">
  <h2>Take a break on Windows</h2>
  <div class="btn-row">
    <a class="btn btn-primary" href="https://github.com/ugurcandede/taplock-windows/releases/latest/download/TapLock.exe">Download TapLock</a>
    <a class="btn btn-ghost" href="https://github.com/ugurcandede/taplock-windows/releases">All releases</a>
  </div>
</div>
