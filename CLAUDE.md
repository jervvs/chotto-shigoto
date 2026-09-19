# Chotto Shigoto (ちょっと仕事)

Native iOS focus session app that blocks distracting apps during timed sessions.

## Build

```bash
xcodebuild -project chottoshigoto.xcodeproj -scheme chottoshigoto -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Tech Stack

- iOS 26.3+, Swift 6.0, SwiftUI
- SwiftData for active session persistence
- JSON file for session history
- App Intents for Shortcuts integration
- Screen Time protection via FamilyControls (mock in DEBUG)

## Key Architecture

- **SessionService** — @Observable state machine (idle/active/completed/logging)
- **PersistedSession** — SwiftData @Model, survives app kills
- **ProtectionService** — protocol with Mock (#if DEBUG) and ScreenTime (#else) implementations
- **App Groups** — `group.com.jervdev.chottoshigoto` for intent ↔ app communication

## App Flow

```
Launch → Recover Session → FocusView (active) / CompletionView (expired) / Home (none)
Start Timer → Focus → Completion → Logging → Home
```

## Conventions

- English-first UI, Japanese accents (仕事, お疲れ様でした)
- No gamification (no streaks, scores, badges)
- Sage green accent (`Color.chottoSage`), never orange
- Contribution grid is the hero visual
