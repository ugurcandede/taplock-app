---
layout: default
title: Home
---

<div class="hero">
  <img src="assets/images/icon.png" alt="TapLock" class="hero-icon">
  <h1>TapLock</h1>
  <p style="margin-bottom: 0 !important;">Temporarily disable keyboard and trackpad input, or take relaxing breaks on your Mac.</p>
  <p><strong>No root required.</strong></p>

  <div style="margin: 16px 0 24px; display: flex; gap: 6px; justify-content: center; align-items: center; flex-wrap: wrap;">
    <a href="https://github.com/ugurcandede/taplock/releases/latest"><img src="https://img.shields.io/github/v/release/ugurcandede/taplock?label=CLI&style=flat-square" alt="CLI Version" height="20"></a>
    <a href="https://github.com/ugurcandede/taplock-app/releases/latest"><img src="https://img.shields.io/github/v/release/ugurcandede/taplock-app?label=App&style=flat-square" alt="App Version" height="20"></a>
    <a href="https://support.apple.com/en-us/109033"><img src="https://img.shields.io/badge/macOS-13.0%2B-000?style=flat-square&logo=apple&logoColor=white" alt="macOS" height="20"></a>
    <a href="https://www.swift.org/install/macos/"><img src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift" height="20"></a>
  </div>

  <div class="hero-install">
    <span class="comment"># Install via Homebrew</span><br>
    brew tap ugurcandede/taplock<br>
    brew install taplock<span class="comment">              # CLI</span><br>
    brew install --cask taplock-app<span class="comment">   # Menu bar app</span>
  </div>
</div>

---

<div class="features">
  <h2>Features</h2>
  <div class="features-grid">
    <div class="feature-card">
      <div class="icon">⌨️</div>
      <h3>Input Blocking</h3>
      <p>Block keyboard, trackpad, and mouse via CGEvent tap at system level.</p>
    </div>
    <div class="feature-card">
      <div class="icon">⏱️</div>
      <h3>Countdown Overlay</h3>
      <p>Full-screen timer with current clock display. Customizable background color.</p>
    </div>
    <div class="feature-card">
      <div class="icon">♾️</div>
      <h3>Flexible Duration</h3>
      <p>Set seconds, minutes, or lock indefinitely with 5-minute safety auto-unlock.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🔅</div>
      <h3>Screen Dimming</h3>
      <p>Reduce brightness to minimum during lock. Automatically restores on unlock.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🔔</div>
      <h3>Sound Feedback</h3>
      <p>Audio cues on lock start and end. Silent mode available.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🚨</div>
      <h3>Emergency Cancel</h3>
      <p>Hold <strong>⌘⌥⌃L</strong> for 3 seconds to cancel any time — always works.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🧘</div>
      <h3>Relaxing Sessions</h3>
      <p>Periodic break reminders with calming overlay themes. Pomodoro-style or custom intervals.</p>
    </div>
    <div class="feature-card">
      <div class="icon">🔒</div>
      <h3>No Root Required</h3>
      <p>Runs with standard user permissions. Only needs Accessibility access — no sudo, no admin.</p>
    </div>
    <div class="feature-card">
      <div class="icon">💾</div>
      <h3>Persistent Config</h3>
      <p>Save your relaxing session settings once. Next time, just run <code>taplock relax</code>.</p>
    </div>
  </div>
</div>

---

<div class="screenshots">
  <h2>Lock Mode</h2>
  <div class="screenshots-row">
    <img src="assets/images/app-infinite.png" alt="Indefinite Mode" width="220">
    <img src="assets/images/app-seconds.png" alt="Custom Duration" width="220">
    <img src="assets/images/settings.png" alt="Settings" width="220">
  </div>
  <img src="assets/images/lock-screen.png" alt="Lock Screen" class="screenshot-full" width="640">
  <p class="screenshot-label">Full-screen countdown overlay during active lock</p>
</div>

---

<div class="screenshots">
  <h2>Relax Mode</h2>
  <div class="screenshots-row">
    <img src="assets/images/relax/app.png" alt="Relax Setup" width="220">
    <img src="assets/images/relax/in-app-countdown.png" alt="Break Countdown" width="220">
    <img src="assets/images/relax/in-app-countdown-2.png" alt="Break Session Countdown" width="220">
    <img src="assets/images/relax/settings.png" alt="Relax Settings" width="220">
  </div>
  <p class="screenshot-label" style="margin-bottom: 16px;"><strong>Overlay Themes</strong></p>
  <div class="screenshots-row">
    <img src="assets/images/relax/minimal.png" alt="Minimal Theme" width="300">
    <img src="assets/images/relax/mini.png" alt="Mini Theme" width="300">
  </div>
  <div class="screenshots-row screenshots-row--lg">
    <img src="assets/images/relax/breathing.png" alt="Breathing Theme">
    <img src="assets/images/relax/breathing-2.png" alt="Breathing Dark">
  </div>
</div>

---

<div class="features">
  <h2>Two Ways to Use</h2>
  <div class="features-grid" style="grid-template-columns: 1fr 1fr;">
    <div class="feature-card">
      <div class="icon">💻</div>
      <h3>CLI</h3>
      <p>Power user friendly. Full control from the terminal with all options and flags.</p>
      <pre style="background:#1a1a2e;color:#e8e8e8;padding:12px;border-radius:8px;font-size:0.85em;margin-top:12px;">taplock 30 --dim --color black
taplock relax --every 25m --break 5m</pre>
    </div>
    <div class="feature-card">
      <div class="icon">🖱️</div>
      <h3>Menu Bar App</h3>
      <p>Lock and Relax modes. Presets, custom input, theme selection — all from the menu bar.</p>
    </div>
  </div>
</div>

---

<div style="text-align:center; padding: 40px 0 20px;">
  <h2>Links</h2>
  <div style="margin: 16px 0 24px; display: flex; gap: 6px; justify-content: center; align-items: center; flex-wrap: wrap;">
    <a href="https://github.com/ugurcandede/taplock"><img src="https://img.shields.io/badge/CLI%20Repo-000?style=flat-square&logo=github&logoColor=white" alt="CLI" height="22"></a>
    <a href="https://github.com/ugurcandede/taplock-app"><img src="https://img.shields.io/badge/App%20Repo-000?style=flat-square&logo=github&logoColor=white" alt="App" height="22"></a>
    <a href="https://github.com/ugurcandede/homebrew-taplock"><img src="https://img.shields.io/badge/Homebrew%20Tap-FBB040?style=flat-square&logo=homebrew&logoColor=000" alt="Homebrew" height="22"></a>
  </div>
</div>

---

<div style="text-align:center; padding: 40px 0 20px;">
  <h2>Requirements</h2>
  <p style="color: var(--text-secondary);">macOS 13.0 (Ventura) or later · Apple Silicon or Intel · Accessibility permission</p>
</div>
