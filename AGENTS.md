# Chotto Shigoto — Agent Guide

## Project Overview

**Chotto Shigoto** (ちょっと仕事) is a native iOS focus session app that blocks distracting apps during timed sessions, with contribution grid tracking, widget integration, Screen Time protection, and session recovery.

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
│   ├── FocusSession.swift          # In-memory session model (timestamp-based)
│   ├── PersistedSession.swift      # SwiftData @Model for active session persistence
│   ├── SessionCategory.swift       # reading/coding/writing/learning/work/other
│   └── SessionState.swift          # idle/active/completed/logging enum
├── Session/
│   └── SessionService.swift        # @Observable state machine, timer, protection, recovery
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift          # Main screen: app name, timer picker, Start button
│   │   ├── ChottoTimerPicker.swift # Horizontal ruler timer (1-180 min, per-minute ticks)
│   │   └── AppPickerView.swift     # FamilyActivityPicker wrapper (#if !DEBUG)
│   ├── Focus/
│   │   └── FocusView.swift         # Full-screen countdown (hours:minutes:seconds)
│   ├── Completion/
│   │   └── CompletionView.swift    # お疲れ様でした + More chotto / Finish
│   ├── Logging/
│   │   └── LoggingView.swift       # Category picker (skipped in main flow, accessed via Finish)
│   ├── Progress/
│   │   └── ProgressView.swift      # Month/Year toggle, contribution grid, Swift Charts, categories
│   └── Settings/
│       ├── SettingsView.swift      # Default Timer, Focus Automation guide, Protection config
│       └── FocusAutomationGuide.swift # Guide for setting up Shortcuts-based Focus automation
├── AppIntents/
│   ├── StartChottoIntent.swift     # Signals start session, returns end time
│   ├── GetEndTimeIntent.swift      # Returns end time of active session or nil
│   └── ChottoShortcutsProvider.swift # Registers phrases for Siri/Shortcuts
├── DesignSystem/
│   └── ChottoColors.swift          # cream/sage/charcoal palette + grid colors
├── Persistence/
│   ├── SessionStore.swift          # JSON file persistence (chotto_history.json)
│   ├── SessionRepository.swift     # SwiftData CRUD wrapper for PersistedSession
│   └── SharedDefaults.swift        # App Group shared UserDefaults for intent communication
├── FocusProtection/
│   ├── ProtectionService.swift     # Protocol (3 methods)
│   ├── MockProtectionService.swift # DEBUG: mock impl, zero FamilyControls deps
│   └── ScreenTimeProtectionService.swift # RELEASE: real impl (#if !DEBUG)
├── Widgets/
│   └── ChottoWidget/
│       ├── ChottoWidget.swift      # idle/active/completed states
│       ├── ChottoWidgetBundle.swift
│       └── StartChottoIntent.swift # WidgetStartChottoIntent (opens app + signals)
├── ContentView.swift               # RootView: TabView or FocusView based on session state
├── chottoshigotoApp.swift          # App entry, recovery, SessionService + SwiftData container
├── chottoshigoto.entitlements      # App Group entitlement
└── Widgets/ChottoWidget/
    └── ChottoWidget.entitlements   # App Group entitlement
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
App Launch (init)
    │
    ├── Recover Session (SwiftData)
    │   ├── Active + future → FocusView (no tabs)
    │   └── Active + expired → CompletionView
    │
    ├── Consume Start Signal (SharedDefaults)
    │   └── Signal exists + idle → start session → FocusView
    │
    └── No session, no signal → Home (TabView)
                                    │
                               Start Timer / Shortcut
                                    │
                                    ▼
                               Focus (countdown) → Completion → Logging → Home
                                                    ↘ More chotto → Focus (reuse same duration)
                                                    ↘ Finish → Logging → Home

Foreground Re-entry (scenePhase → .active)
    │
    ├── Session already active → ignore signal
    └── Idle + signal exists → start session → FocusView
```

### Key Behaviors
- **Default timer**: Configurable in Settings (1–180 min), Home reads from `@AppStorage("defaultTimerMinutes")` on appear
- **Timer picker**: 1–180 minutes, per-minute increments, labels every 5 min, smooth scroll with `.scrollTargetBehavior(.viewAligned)`
- **Duration display**: Shows `HH:MM:SS` when over 1 hour, `MM:SS` otherwise
- **"Start Timer"** is the exact button text (English)
- **"More chotto"** reuses the same duration as the completed session
- **Finish** goes to Logging page (category picker), then saves and returns to Home
- **Logging page** can be skipped via "Skip" button
- **Session recovery**: App detects active/expired sessions on launch via SwiftData
- **Navigation lock**: Active session shows FocusView only — no tabs, no navigation

## Models

### FocusSession (in-memory)
```swift
struct FocusSession: Identifiable, Codable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    var completed: Bool
    let plannedDuration: TimeInterval
    var category: SessionCategory?

    var actualDuration: TimeInterval  // computed from timestamps
    func remainingSeconds(at: Date) -> TimeInterval  // computed
}
```

### PersistedSession (SwiftData)
```swift
@Model
final class PersistedSession {
    var id: UUID
    var startedAt: Date
    var plannedDuration: TimeInterval
    var completedAt: Date?
    var categoryRaw: String?

    var endDate: Date { startedAt.addingTimeInterval(plannedDuration) }
    var isActive: Bool { completedAt == nil }
    var actualDuration: TimeInterval { ... }
    var category: SessionCategory? { get/set }
}
```

### SessionRecord (JSON history)
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
.idle → startSession() → .active(session) [persists to SwiftData]
.active → completeSession() → .completed(session) [marks SwiftData complete]
.completed → moreChotto() → .active(newSession) [persists new session]
.completed → proceedToLogging() → .logging(session)
.logging → logCategory() → .idle [saves to history JSON, deletes active]
.logging → skipLogging() → .idle [saves to history JSON, deletes active]
```

### Launch Recovery
```
recoverSession() → .noActiveSession | .resume(session) | .expired(session)
```
- `.resume` → `resumePersistedSession()` → enters FocusView with timer
- `.expired` → `showExpiredCompletion()` → shows CompletionView
- `.noActiveSession` → normal Home
- Recovery happens in `init()` so the correct view appears immediately (no transition)

## Settings

### Default Timer
- `@AppStorage("defaultTimerMinutes")` — persists preferred duration (default: 25)
- Typable text field (1–180 min) in Settings
- Home timer initializes from this value on appear

### Focus Automation
- Guide explains how to create personal automations in Shortcuts app
- Trigger: App → Chotto → Is Opened → Set Focus On
- Trigger: App → Chotto → Is Closed → Set Focus Off
- Chotto cannot directly control system Focus — this is an Apple limitation

## App Intents

### StartChottoIntent
- `openAppWhenRun = true` — brings app to foreground
- Signals start session via shared UserDefaults (`SharedDefaults.signalStartSession()`)
- Returns end time as `Date` variable for Shortcuts automation
- Signal is ignored if a session is already active

### GetEndTimeIntent
- Returns end time of current active session, or `nil` if no session
- Useful for Shortcuts to check if a session is active and schedule Focus accordingly

### ChottoShortcutsProvider
- Registers phrases for Siri/Shortcuts
- Phrases: "Start a chotto in Chotto", "Get chotto end time in Chotto"

### Signal Communication (SharedDefaults)
- Intent writes `pendingStartSession = true` to App Group UserDefaults
- App consumes the signal on **cold launch** (in `init()`) and on **foreground entry** (`scenePhase` → `.active`)
- Signal is only consumed when state is `.idle` — ignored if session is already active
- `SharedDefaults` uses a cached `UserDefaults` instance for reliable persistence

### Shortcuts Automation Flow
```
1. Start Chotto        → provides "End Time" variable, opens app
2. Set Focus On        → turns on Work Focus
3. Wait until End Time → (optional)
4. Set Focus Off       → turns off Work Focus
```

## Progress Page

### Month View
- Contribution grid (week columns, day rows, S-M-T-W-T-F-S)
- Practice section: Chottos/week bar chart (W1, W2, W3...) + Average Chotto line chart
- Category breakdown: horizontal bars with counts

### Year View
- Monthly Chottos bar chart
- Monthly average duration line chart
- Category breakdown

### Data Model
All progress data is **derived from SessionStore.history** — no pre-aggregated statistics are persisted.

## Screen Time Protection

### Architecture
- `ProtectionService` protocol (3 methods: requestAuthorization, activate, deactivate)
- `MockProtectionService` (#if DEBUG) — no FamilyControls dependency
- `ScreenTimeProtectionService` (#else) — real FamilyControls + ManagedSettings
- Injected via `SessionService(protection:)` protocol injection

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
- **WidgetStartChottoIntent**: Opens app + signals start session via App Groups
- **App Group**: `group.com.jervdev.chottoshigoto` — shared UserDefaults for intent communication

## Git Workflow

- **Branch**: `feat/session-recovery-default-timer`
- **Xcode project**: `project.pbxproj` uses `PBXFileSystemSynchronizedRootGroup` (objectVersion 77) — files in tracked directories are auto-included
- **Shared scheme**: `chottoshigoto.xcodeproj/xcshareddata/xcschemes/chottoshigoto.xcscheme`
- **Development team**: `QHSJ4Z34B8` is set in project.pbxproj
- **App Group**: `group.com.jervdev.chottoshigoto` (both entitlements files)

## Known Issues / TODO

1. **App protection persistence**: `ApplicationToken` objects are ephemeral. Need to implement bundle ID persistence for production.
2. **Timer picker logo**: Logo should be placed above the timer display in HomeView (48x48pt, image named "logo" in Assets.xcassets).
3. **Year view empty state**: Year view shows empty charts when no data exists for future months.
4. **Widget App Groups**: Widget reads from shared UserDefaults but doesn't yet display active session state.
5. **Focus automation**: System Focus integration requires user to create personal automations in Shortcuts app. Chotto cannot directly control system Focus.

## Conventions

- **Kanji**: Use 仕事 (not しごと) throughout
- **Japanese text**: お疲れ様です (completion), ちょっと仕事 (subtitle)
- **English-first**: Button labels, section titles in English
- **No gamification**: No streaks, scores, percentages, badges, or negative language
- **Progressive disclosure**: Simple by default, details on tap
- **Contribution grid is the hero visual** — make it prominent, not tiny
