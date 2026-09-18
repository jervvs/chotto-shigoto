# Chotto Shigoto — Agent Guide

## Project Overview

**Chotto Shigoto** (ちょっと仕事) is a native iOS focus session app that blocks distracting apps during timed sessions, with contribution grid tracking, widget integration, and Screen Time protection.

**English-first UI with Japanese accents.**

## Tech Stack

- **Platform**: iOS 26.3+, Swift 6.0, SwiftUI
- **IDE**: Xcode 26.2
- **Testing target**: iPhone 17 simulator (iPhone 16 does NOT exist on this machine)
- **Build command**:
  ```bash
  xcodebuild -project chottoshigoto.xcodeproj -scheme chottoshigoto -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```

## Project Structure

```
chottoshigoto/
├── Domain/
│   ├── FocusSession.swift          # Session model (timestamp-based, computed actualDuration)
│   ├── SessionCategory.swift       # reading/coding/writing/learning/work/other
│   └── SessionState.swift          # idle/active/completed/logging enum
├── Session/
│   └── SessionService.swift        # @Observable state machine, timer, protection integration
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift          # Main screen: app name, timer picker, Start button
│   │   ├── ChottoTimerPicker.swift # Horizontal ruler timer (1-180 min, per-minute ticks)
│   │   └── AppPickerView.swift     # FamilyActivityPicker wrapper
│   ├── Focus/
│   │   └── FocusView.swift         # Full-screen countdown (hours:minutes:seconds)
│   ├── Completion/
│   │   └── CompletionView.swift    # お疲れ様でした + More chotto / Finish
│   ├── Logging/
│   │   └── LoggingView.swift       # Category picker (skipped in main flow, accessed via Finish)
│   ├── Progress/
│   │   └── ProgressView.swift      # Month/Year toggle, contribution grid, Swift Charts, categories
│   └── Settings/
│       └── SettingsView.swift      # App Protection + Whitelist config
├── DesignSystem/
│   └── ChottoColors.swift          # cream/sage/charcoal palette + grid colors
├── Persistence/
│   └── SessionStore.swift          # JSON file persistence (chotto_history.json)
├── FocusProtection/
│   └── FocusProtectionService.swift # FamilyControls + ManagedSettings, whitelist support
├── Widgets/
│   └── ChottoWidget/
│       ├── ChottoWidget.swift      # idle/active/completed states
│       ├── ChottoWidgetBundle.swift
│       └── StartChottoIntent.swift
├── ContentView.swift               # RootView: TabView (Home/Progress/Settings)
├── chottoshigotoApp.swift          # App entry, owns SessionService + SessionStore
└── chottoshigoto.entitlements      # family-controls entitlement
```

## Design Tokens

### Colors (`ChottoColors.swift`)
```swift
Color.chottoCream          // RGB(0.98, 0.96, 0.93) — background
Color.chottoSage           // RGB(0.65, 0.72, 0.60) — primary accent (green)
Color.chottoSageDeep       // RGB(0.45, 0.58, 0.42) — selected states
Color.chottoCharcoal       // RGB(0.18, 0.18, 0.18) — text
Color.chottoTerracotta     // RGB(0.76, 0.52, 0.42) — reserved

// Grid colors (contribution calendar)
Color.chottoGridEmpty      // RGB(0.93, 0.91, 0.88)
Color.chottoGridLevel1     // RGB(0.82, 0.87, 0.79)
Color.chottoGridLevel2     // RGB(0.65, 0.76, 0.60)
Color.chottoGridLevel3     // RGB(0.48, 0.65, 0.45)
Color.chottoGridLevel4     // RGB(0.35, 0.52, 0.33)
```

**IMPORTANT**: All accent color in charts and UI is **sage green** (`Color.chottoSage`), NOT orange. Never use `.orange` — it's been replaced throughout the app.

### Typography
- App name: `.system(size: 28, weight: .light, design: .serif)` — "chotto 仕事"
- Subtitle: `.system(size: 13, weight: .regular)` — "ちょっと仕事"
- Timer display: `.system(size: 48, weight: .thin, design: .monospaced)`
- Section headers: `.system(size: 20, weight: .light, design: .serif)`

## App Flow

```
Home (timer picker) → Focus (countdown) → Completion (お疲れ様でした) → Logging (category) → Home
                                         ↘ More chotto → Focus (reuse same duration)
                                         ↘ Finish → Logging → Home
```

### Key Behaviors
- **Timer picker**: 1–180 minutes, per-minute increments, labels every 5 min, horizontal drag, haptics, AppStorage persistence (default 25 min)
- **Duration display**: Shows `HH:MM:SS` when over 1 hour, `MM:SS` otherwise
- **"Start Timer"** is the exact button text (English)
- **"More chotto"** reuses the same duration as the completed session
- **Finish** goes to Logging page (category picker), then saves and returns to Home
- **Logging page** can be skipped via "Skip" button

## Models

### FocusSession
```swift
struct FocusSession: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    var completed: Bool
    let plannedDuration: TimeInterval
    var category: SessionCategory?

    var actualDuration: TimeInterval  // computed from timestamps
    func remainingSeconds(at: Date: TimeInterval  // computed
}
```

### SessionRecord (persistence)
```swift
struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let duration: TimeInterval
    let category: SessionCategory
}
```

### SessionCategory
```swift
enum SessionCategory: String, CaseIterable, Codable {
    case reading, coding, writing, learning, work, other
}
```

## SessionService State Machine

```
.idle → startSession() → .active(session)
.active → completeSession() → .completed(session)
.completed → moreChotto() → .active(newSession)
.completed → proceedToLogging() → .logging(session)
.logging → logCategory() → .idle (saves session)
.logging → skipLogging() → .idle (saves session)
```

## Progress Page

### Month View
- Contribution grid (week columns, day rows, M/W/F labels removed — shows all S-M-T-W-T-F-S)
- Practice section: Chottos/week bar chart + Average Chotto line chart (Swift Charts)
- Category breakdown: horizontal bars with counts

### Year View
- Monthly Chottos bar chart
- Monthly average duration line chart
- Category breakdown

### Data Model
All progress data is **derived from SessionStore.history** — no pre-aggregated statistics are persisted.

## Screen Time Protection

### Entitlements
- `chottoshigoto.entitlements`: `com.apple.developer.family-controls`
- `ChottoWidget.entitlements`: `com.apple.developer.family-controls` + `com.apple.developer.managed-settings`

### Flow
1. User taps "Set up" in Settings
2. `requestAuthorization(for: .individual)` — prompts Screen Time access
3. `FamilyActivityPicker` opens — user selects apps to block
4. `shieldApps(tokens)` — sets `ManagedSettingsStore.shield.applications`
5. During focus session, selected apps are shielded (blurred icon, blocked access)

### Known Limitation
- **Simulator**: FamilyControls does not work on iOS Simulator. Must test on physical device.
- **Ephemeral tokens**: `ApplicationToken` objects don't persist across app launches. For MVP, user must re-select apps each session.
- **Whitelist**: High-priority apps (PagerDuty, Slack, Phone, Messages, Mail) are whitelisted by default.

## Widget

- **States**: idle (chotto 仕事), active (仕事中 + remaining), completed (お疲れ様でした)
- **Entry**: `ChottoWidgetBundle`, `StartChottoIntent` for quick start from widget

## Git Workflow

- **Branch**: `feat/slice-1-core-session-engine` (not pushed)
- **Xcode project**: `project.pbxproj` uses `PBXFileSystemSynchronizedRootGroup` (objectVersion 77) — files in tracked directories are auto-included
- **Shared scheme**: `chottoshigoto.xcodeproj/xcshareddata/xcschemes/chottoshigoto.xcscheme`
- **Development team**: `QHSJ4Z34B8` is set in project.pbxproj

## Known Issues / TODO

1. **App protection persistence**: `ApplicationToken` objects are ephemeral. Need to implement bundle ID persistence for production.
2. **Timer picker logo**: Logo should be placed above the timer display in HomeView (48x48pt, image named "logo" in Assets.xcassets).
3. **Year view empty state**: Year view shows empty charts when no data exists for future months.
4. **Widget entitlements**: Widget extension entitlements need to be configured for production.

## Conventions

- **Kanji**: Use 仕事 (not しごと) throughout
- **Japanese text**: お疲れ様です (completion), ちょっと仕事 (subtitle)
- **English-first**: Button labels, section titles in English
- **No gamification**: No streaks, scores, percentages, badges, or negative language
- **Progressive disclosure**: Simple by default, details on tap
- **Contribution grid is the hero visual** — make it prominent, not tiny
