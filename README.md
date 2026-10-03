# Chotto Shigoto (ちょっと仕事)

> **Just a little work** — A focus session app that trains your attention like a muscle.

---

## The Problem

I'm easily distracted. After doing a bit of work, I reach for my phone — Instagram, Twitter, TikTok. Notifications pull me away. What starts as "just a quick check" turns into an hour lost.

Sound familiar?

## The Insight

I saw a video about how the brain is like a muscle. **Attention can be trained** — progressively overloaded, just like lifting weights.

As a regular gym-goer, this clicked. Why not treat focus the same way?

## The Solution: Chotto Shigoto

Not just a Pomodoro timer. A **focus training system** built on three pillars:

### 🏋️ Progressive Overload for Your Attention
- **Custom durations** — 1 to 180 minutes, not locked to 25
- **Metrics that matter** — Session history, weekly/monthly contribution grids, category breakdowns
- **Visual progress** — Watch your focus capacity grow over weeks and months
- **More chotto** — Completed a session? Do another with the same duration. Build volume.

### 🧠 Habit-Inducing UX
- **Name is the hook** — *Chotto shigoto* (ちょっと仕事) = "just a little work." Same wiring that makes "just 5 minutes on Instagram" turn into hours — now redirected to work.
- **Low friction start** — Horizontal ruler timer picker, one-tap start
- **Shortcuts integration** — "Hey Siri, start a chotto" → opens app, begins session, returns end time for Focus automation
- **Completion ritual** — *お疲れ様でした* (thank you for your hard work) + category logging → dopamine hit

### 🛡️ Real App Blocking (with a catch)
- **Screen Time API** — Blocks selected apps during sessions via `ManagedSettings`
- **Whitelist** — Critical apps (Phone, Messages, Slack, PagerDuty) stay accessible
- **Current limitation** — Requires paid Apple Developer account for full Family Controls entitlements
- **Workaround included** — [Focus Automation Guide](chottoshigoto/Features/Settings/FocusAutomationGuide.swift) shows how to create a personal Shortcut: *App Opens → Focus On, App Closes → Focus Off*

---

## Current State

| Feature | Status |
|---------|--------|
| Custom timer (1–180 min) | ✅ |
| Session persistence & recovery | ✅ SwiftData |
| Contribution grid (month/year) | ✅ Swift Charts |
| Category logging | ✅ |
| Shortcuts / Siri intents | ✅ `StartChottoIntent`, `GetEndTimeIntent` |
| Widget (idle/active/completed) | ✅ WidgetKit |
| Screen Time app blocking | ⚠️ Requires paid dev account for full entitlements |
| Focus Mode automation | 📖 Guide in Settings → Shortcuts setup |

**Test target:** iPhone 17 Simulator (iOS 26.3+)

---

## Architecture Highlights

```
Domain/           # Pure models: FocusSession, PersistedSession, SessionCategory
Session/          # @Observable SessionService — state machine + timer + recovery
Features/         # Home, Focus, Completion, Logging, Progress, Settings
AppIntents/       # StartChottoIntent, GetEndTimeIntent, ShortcutsProvider
FocusProtection/  # Protocol + Mock (DEBUG) + ScreenTime (RELEASE) implementations
Persistence/      # SessionStore (JSON), SessionRepository (SwiftData), SharedDefaults (App Groups)
Widgets/          # ChottoWidget + WidgetStartChottoIntent
```

- **Protocol-based DI** for protection service — testable, no FamilyControls in DEBUG
- **App Groups** for intent↔app communication (`group.com.jervdev.chottoshigoto`)
- **Launch recovery** — detects active/expired sessions in `init()`, shows correct view immediately
- **Navigation lock** — active session = FocusView only, no tabs

---

## Design System

| Color | Purpose |
|-------|---------|
| `chottoCream` | Background |
| `chottoSage` | Primary accent (green — never orange) |
| `chottoSageDeep` | Selected states |
| `chottoCharcoal` | Text |
| Grid levels 1–4 | Contribution calendar intensity |

Typography: Serif for headers ("chotto 仕事"), monospaced for timers, system for UI.

---

## Building

```bash
xcodebuild -project chottoshigoto.xcodeproj \
  -scheme chottoshigoto \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**Requirements:** Xcode 26.2, iOS 26.3+, Swift 6.0

---

## The Name

**Chotto Shigoto** (ちょっと仕事)

- *Chotto* = a little, just a bit
- *Shigoto* = work

It reframes work as "just a little bit" — the same mental trick that makes doom-scrolling feel harmless. Except now it builds something.

---

## Roadmap

- [ ] Bundle ID persistence for app tokens (survive app reinstalls)
- [ ] Year view empty state handling
- [ ] Widget active session state display
- [ ] Paid dev account → full Family Controls entitlements
- [ ] CloudKit sync for multi-device history

---

## License

MIT — Build your attention muscle.