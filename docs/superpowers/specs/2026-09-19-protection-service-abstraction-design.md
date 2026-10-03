# ProtectionService Abstraction

## Goal

Decouple the app from Apple's FamilyControls/ManagedSettings entitlement so the entire MVP can be developed and tested on a free Personal Team. Protection becomes a protocol with two implementations: a mock (DEBUG) and the real ScreenTime service (Release).

## Architecture

```
              SessionService
                   │
                   ▼
          ProtectionService (protocol)
             /           \
            /             \
           ▼               ▼
  MockProtection     ScreenTimeProtection
```

## Protocol

```swift
protocol ProtectionService {
    func requestAuthorization() async throws
    func activate() async throws
    func deactivate() async throws
}
```

- `requestAuthorization()` — prompts for Screen Time access (mock: always succeeds)
- `activate()` — shields selected apps (mock: no-op, logs action)
- `deactivate()` — removes shields (mock: no-op, logs action)

## Implementations

### MockProtectionService

- Used in `#if DEBUG` builds
- `requestAuthorization()` — returns immediately (always authorized)
- `activate()` — logs "Mock: protection activated"
- `deactivate()` — logs "Mock: protection deactivated"
- No FamilyControls/ManagedSettings imports
- No `ApplicationToken` or `FamilyActivitySelection` types

### ScreenTimeProtectionService

- Used in Release builds
- Wraps existing `FocusProtectionService` logic
- Conforms to `ProtectionService` protocol
- Retains whitelist management, `ManagedSettingsStore`, `AuthorizationCenter`
- Manages `ApplicationToken` internally (not exposed through protocol)

## Injection

SwiftUI environment injection from `chottoshigotoApp.swift`:

```swift
@main
struct chottoshigotoApp: App {
    @State private var sessionService: SessionService
    @State private var sessionStore = SessionStore()

    init() {
        #if DEBUG
        let protection: ProtectionService = MockProtectionService()
        #else
        let protection: ProtectionService = ScreenTimeProtectionService()
        #endif
        _sessionService = State(initialValue: SessionService(protection: protection))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionService)
                .environment(sessionStore)
        }
    }
}
```

## File Changes

### New files

| File | Purpose |
|------|---------|
| `FocusProtection/ProtectionService.swift` | Protocol definition |
| `FocusProtection/MockProtectionService.swift` | Mock implementation |

### Modified files

| File | Change |
|------|--------|
| `FocusProtection/FocusProtectionService.swift` | Rename to `ScreenTimeProtectionService`, conform to protocol, remove singleton pattern, accept init |
| `Session/SessionService.swift` | Replace `FocusProtectionService.shared` with injected `ProtectionService` dependency |
| `chottoshigotoApp.swift` | Create appropriate implementation via `#if DEBUG`, inject into `SessionService` |
| `Features/Settings/SettingsView.swift` | `#if DEBUG` to show simplified mock status (no FamilyActivityPicker) |
| `Features/Home/AppPickerView.swift` | `#if DEBUG` guard or conditional compilation |

## SettingsView Mock Mode

In `#if DEBUG`, the Settings protection section shows:
- Status: "Mock Protection Active" with a checkmark
- No "Set up" button (no app selection needed)
- Whitelist section hidden (not relevant for mock)

The `FamilyActivityPicker` sheet and related FamilyControls imports are wrapped in `#if !DEBUG`.

## SessionService Changes

Current:
```swift
let protection = FocusProtectionService.shared
```

New:
```swift
private let protection: ProtectionService

init(protection: ProtectionService) {
    self.protection = protection
}
```

The `applyProtection()` and `removeProtection()` methods call `protection.activate()` and `protection.deactivate()` instead of accessing `protection.selectedApps` directly.

## Testing

- All existing features (timer, focus screen, progress grid, charts, categories, more chotto) work unchanged
- Protection "activates" during focus sessions (mock just logs)
- Settings shows simplified mock status
- No FamilyControls entitlement required for DEBUG builds
- Widget continues to work (separate target, unaffected)
