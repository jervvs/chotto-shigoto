# Session Recovery, Default Timer & Navigation Lock

## Context

The app currently loses all session state on launch. If the user starts a focus session, kills the app, and reopens it, the session is gone. The timer also resets to 25 every time regardless of any settings. This plan adds:

1. **Default timer setting** — persist preferred duration in AppStorage
2. **Persistent session model** — SwiftData-based session that survives app kills
3. **Launch recovery** — detect active/expired sessions on launch and route accordingly
4. **Root navigation lock** — active session shows FocusView only, no tabs
5. **App Intents** — expose Start/End Chotto to Shortcuts (framework for future Focus automation)

## Architecture Decisions

- **SwiftData over JSON file**: Replace `SessionStore` JSON persistence with SwiftData `@Model` for the active session. Keep JSON history for completed sessions (already works).
- **Dual persistence**: Active session → SwiftData (survives kill). Completed session history → JSON (Progress view reads from this).
- **Recovery at App level**: `chottoshigotoApp` checks for active session before rendering `RootView`.
- **Navigation lock via root**: `RootView` switches between `TabView` and `FocusView` based on session state — not by hiding tabs.
- **Focus integration deferred**: App Intents are built now but Focus automation is a spike (Step 7 in spec). Don't block session engine on it.

## Implementation Tasks

### Task 1: Default Timer Setting
- Add `@AppStorage("defaultTimerMinutes")` to `HomeView`
- Home timer picker initializes from setting, not hardcoded 25
- Add `DefaultTimerSetting` row in `SettingsView` with same picker UX
- Picker range: 5–60 minutes

### Task 2: SwiftData Session Model
- Create `PersistedSession` SwiftData `@Model` class in `Domain/`
- Properties: id, startedAt, plannedDuration, completedAt, category
- Computed: `endDate`, `isActive`, `actualDuration`
- Add `@ModelContainer` to `chottoshigotoApp`
- Add `modelContainer` environment to `RootView`

### Task 3: Session Repository
- Create `SessionRepository` class that wraps SwiftData operations
- Methods: `activeSession()`, `save(_:)`, `complete(_:)`, `delete(_:)`
- Inject via environment from app entry point

### Task 4: SessionService Refactor
- `SessionService` creates and persists `PersistedSession` via repository
- `startSession()` → create + persist + protect + enter focus
- `completeSession()` → mark completed + unprotect
- `finishSession()` → move to history + delete active
- Timer still runs in-memory but reads from persisted session

### Task 5: Launch Recovery
- `chottoshigotoApp` calls `recoverSession()` before body
- Three outcomes: `.resume(session)`, `.expired(session)`, `.noActiveSession`
- Pass recovery result to `RootView`

### Task 6: Root Navigation Lock
- `RootView` takes `SessionRecoveryResult` parameter
- `.resume` → show `FocusView` (no tabs, no navigation)
- `.expired` → show `CompletionView`
- `.noActiveSession` → show `TabView` (normal)
- When `SessionState` changes to `.active`, also lock to FocusView

### Task 7: App Intents
- Create `AppIntents/StartChottoIntent.swift`
- Create `AppIntents/EndChottoIntent.swift`
- Create `AppIntents/ChottoShortcutsProvider.swift`
- These call the same `SessionService` methods

## Verification
- Build: `xcodebuild -project chottoshigoto.xcodeproj -scheme chottoshigoto -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Test: Start session → kill app → relaunch → should show FocusView or CompletionView
- Test: Change default timer in Settings → return to Home → picker shows new default
- Test: During active session, tab bar should not be accessible
