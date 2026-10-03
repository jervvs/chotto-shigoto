# ProtectionService Abstraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decouple the app from FamilyControls/ManagedSettings entitlement by introducing a `ProtectionService` protocol with mock and real implementations.

**Architecture:** Protocol-based dependency injection. `SessionService` depends on `ProtectionService` protocol. Two concrete implementations: `MockProtectionService` (DEBUG) and `ScreenTimeProtectionService` (Release). Injected via SwiftUI environment from app entry point.

**Tech Stack:** Swift 6.0, SwiftUI, FamilyControls (Release only), ManagedSettings (Release only)

## Global Constraints

- iOS 26.3+, Swift 6.0, SwiftUI
- English-first UI with Japanese accents
- Use 仕事 (not しごと) throughout
- No gamification, no streaks, no scores
- Build command: `xcodebuild -project chottoshigoto.xcodeproj -scheme chottoshigoto -destination 'platform=iOS Simulator,name=iPhone 17' build`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `FocusProtection/ProtectionService.swift` | **Create** | Protocol definition |
| `FocusProtection/MockProtectionService.swift` | **Create** | Mock implementation (DEBUG) |
| `FocusProtection/FocusProtectionService.swift` | **Rename** to `ScreenTimeProtectionService.swift` | Real implementation, conform to protocol |
| `Session/SessionService.swift` | **Modify** | Accept `ProtectionService` protocol injection |
| `chottoshigotoApp.swift` | **Modify** | Create and inject appropriate implementation |
| `Features/Settings/SettingsView.swift` | **Modify** | `#if DEBUG` to hide FamilyControls UI |
| `Features/Home/AppPickerView.swift` | **Modify** | `#if !DEBUG` guard |

---

### Task 1: Create ProtectionService protocol and MockProtectionService

**Files:**
- Create: `chottoshigoto/FocusProtection/ProtectionService.swift`
- Create: `chottoshigoto/FocusProtection/MockProtectionService.swift`

**Interfaces:**
- Produces: `ProtectionService` protocol (consumed by SessionService in Task 3)
- Produces: `MockProtectionService` class (consumed by app entry point in Task 4)

- [ ] **Step 1: Create ProtectionService protocol**

Create `chottoshigoto/FocusProtection/ProtectionService.swift`:

```swift
import Foundation

protocol ProtectionService {
    func requestAuthorization() async throws
    func activate() async throws
    func deactivate() async throws
}
```

- [ ] **Step 2: Create MockProtectionService**

Create `chottoshigoto/FocusProtection/MockProtectionService.swift`:

```swift
import Foundation
import os

final class MockProtectionService: ProtectionService {
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "MockProtection")

    func requestAuthorization() async throws {
        logger.info("Mock: authorization requested - granted automatically")
    }

    func activate() async throws {
        logger.info("Mock: protection activated (no real blocking)")
    }

    func deactivate() async throws {
        logger.info("Mock: protection deactivated")
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add chottoshigoto/FocusProtection/ProtectionService.swift chottoshigoto/FocusProtection/MockProtectionService.swift
git commit -m "feat: add ProtectionService protocol and MockProtectionService"
```

---

### Task 2: Rename and refactor FocusProtectionService to ScreenTimeProtectionService

**Files:**
- Rename: `chottoshigoto/FocusProtection/FocusProtectionService.swift` to `ScreenTimeProtectionService.swift`
- Modify: `chottoshigoto/FocusProtection/ScreenTimeProtectionService.swift`

**Interfaces:**
- Consumes: `ProtectionService` protocol (from Task 1)
- Produces: `ScreenTimeProtectionService` class conforming to `ProtectionService`

- [ ] **Step 1: Rename the file**

```bash
git mv chottoshigoto/FocusProtection/FocusProtectionService.swift chottoshigoto/FocusProtection/ScreenTimeProtectionService.swift
```

- [ ] **Step 2: Rewrite ScreenTimeProtectionService**

Replace the entire content of `chottoshigoto/FocusProtection/ScreenTimeProtectionService.swift`:

```swift
import Foundation
import FamilyControls
import ManagedSettings
import os

@Observable
final class ScreenTimeProtectionService: ProtectionService {
    private(set) var isAuthorized = false
    private(set) var isProtecting = false
    private(set) var selectedApps: [ApplicationToken] = []
    private(set) var whitelistedApps: [String] = []

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "ScreenTimeProtection")

    init() {
        whitelistedApps = Self.defaultWhitelistedApps
        loadWhitelist()
    }

    // MARK: - Default Whitelist (high-priority alert apps)

    static let defaultWhitelistedApps: [String] = [
        "com.pagerduty.PagerDuty",
        "com.slack.Slack",
        "com.apple.mobilephone",
        "com.apple.MobileSMS",
        "com.apple.mobilemail",
    ]

    // MARK: - ProtectionService

    func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
            logger.info("Authorization granted")
        } catch {
            logger.error("Authorization failed: \(error.localizedDescription)")
            isAuthorized = false
            throw error
        }
    }

    func activate() async throws {
        guard !selectedApps.isEmpty else {
            logger.info("No apps selected for protection")
            return
        }
        store.shield.applications = Set(selectedApps)
        isProtecting = true
        logger.info("Shielded \(selectedApps.count) apps")
    }

    func deactivate() async throws {
        store.clearAllSettings()
        isProtecting = false
        logger.info("All shields removed")
    }

    // MARK: - App Selection (ScreenTime-specific)

    func shieldApps(_ tokens: [ApplicationToken]) {
        guard !tokens.isEmpty else {
            logger.warning("No apps to shield")
            return
        }
        selectedApps = tokens
        store.shield.applications = Set(tokens)
        isProtecting = true
        logger.info("Shielded \(tokens.count) apps")
    }

    // MARK: - Whitelist

    func addToWhitelist(bundleId: String) {
        guard !whitelistedApps.contains(bundleId) else { return }
        whitelistedApps.append(bundleId)
        saveWhitelist()
        logger.info("Added \(bundleId) to whitelist")
    }

    func removeFromWhitelist(bundleId: String) {
        whitelistedApps.removeAll { $0 == bundleId }
        saveWhitelist()
        logger.info("Removed \(bundleId) from whitelist")
    }

    func isWhitelisted(bundleId: String) -> Bool {
        whitelistedApps.contains(bundleId)
    }

    // MARK: - Persist Whitelist

    private func saveWhitelist() {
        UserDefaults.standard.set(whitelistedApps, forKey: "whitelistedApps")
    }

    private func loadWhitelist() {
        if let saved = UserDefaults.standard.stringArray(forKey: "whitelistedApps") {
            whitelistedApps = saved
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add chottoshigoto/FocusProtection/ScreenTimeProtectionService.swift
git commit -m "refactor: rename FocusProtectionService to ScreenTimeProtectionService, conform to protocol"
```

---

### Task 3: Update SessionService to use protocol injection

**Files:**
- Modify: `chottoshigoto/Session/SessionService.swift`

**Interfaces:**
- Consumes: `ProtectionService` protocol (from Task 1)
- Produces: `SessionService` init accepting `ProtectionService` (consumed by app entry point in Task 4)

- [ ] **Step 1: Replace hardcoded dependency with protocol injection**

Replace the entire content of `chottoshigoto/Session/SessionService.swift`:

```swift
import Foundation
import Combine
import os

@Observable
final class SessionService {
    private(set) var state: SessionState = .idle
    private var timer: AnyCancellable?

    private let protection: ProtectionService
    private let logger = Logger(subsystem: "com.jervdev.chottoshigoto", category: "SessionService")

    init(protection: ProtectionService) {
        self.protection = protection
    }

    var currentSession: FocusSession? {
        switch state {
        case .active(let session), .completed(let session), .logging(let session):
            return session
        case .idle:
            return nil
        }
    }

    var isRunning: Bool {
        if case .active = state { return true }
        return false
    }

    // MARK: - Actions

    func startSession(plannedDuration: TimeInterval = 25 * 60) {
        let session = FocusSession(plannedDuration: plannedDuration)
        state = .active(session)
        startTimer()
        Task { await applyProtection() }
        logger.info("Session started: \(session.id)")
    }

    func completeSession() {
        guard case .active(let session) = state else { return }
        stopTimer()
        Task { await removeProtection() }

        var finished = session
        finished.endedAt = Date()
        finished.completed = true

        state = .completed(finished)
        logger.info("Session completed: \(finished.id)")
    }

    func moreChotto() {
        guard case .completed(let session) = state else { return }

        let newSession = FocusSession(plannedDuration: session.plannedDuration)
        state = .active(newSession)
        startTimer()
        Task { await applyProtection() }
        logger.info("mou chotto started: \(newSession.id)")
    }

    func proceedToLogging() {
        guard case .completed(let session) = state else { return }
        state = .logging(session)
    }

    func finishSession(store: SessionStore) {
        guard case .completed(let session) = state else { return }
        store.saveSession(session)
        state = .idle
        logger.info("Session finished: \(session.id)")
    }

    func logCategory(_ category: SessionCategory, store: SessionStore) {
        guard case .logging(let session) = state else { return }
        var logged = session
        logged.category = category
        store.saveSession(logged)
        state = .idle
        logger.info("Session logged: \(logged.id) as \(category.rawValue)")
    }

    func skipLogging(store: SessionStore) {
        guard case .logging(let session) = state else { return }
        store.saveSession(session)
        state = .idle
    }

    func discardSession() {
        stopTimer()
        Task { await removeProtection() }
        state = .idle
    }

    func restoreActiveSession() {
        state = .idle
    }

    // MARK: - Protection

    private func applyProtection() async {
        do {
            try await protection.activate()
        } catch {
            logger.error("Protection activation failed: \(error.localizedDescription)")
        }
    }

    private func removeProtection() async {
        do {
            try await protection.deactivate()
        } catch {
            logger.error("Protection deactivation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if case .active(let session) = self.state {
                    if session.remainingSeconds(at: Date()) <= 0 {
                        self.completeSession()
                    }
                }
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        stopTimer()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add chottoshigoto/Session/SessionService.swift
git commit -m "refactor: SessionService accepts injected ProtectionService protocol"
```

---

### Task 4: Update app entry point for dependency injection

**Files:**
- Modify: `chottoshigoto/chottoshigotoApp.swift`

**Interfaces:**
- Consumes: `MockProtectionService` (from Task 1), `ScreenTimeProtectionService` (from Task 2), `SessionService` (from Task 3)

- [ ] **Step 1: Replace app entry point with DI logic**

Replace the entire content of `chottoshigoto/chottoshigotoApp.swift`:

```swift
import SwiftUI

@main
struct chottoshigotoApp: App {
    @State private var sessionService: SessionService
    @State private var sessionStore = SessionStore()

    init() {
        let protection: ProtectionService
        #if DEBUG
        protection = MockProtectionService()
        #else
        protection = ScreenTimeProtectionService()
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

- [ ] **Step 2: Commit**

```bash
git add chottoshigoto/chottoshigotoApp.swift
git commit -m "feat: inject ProtectionService via dependency injection at app entry"
```

---

### Task 5: Update SettingsView and AppPickerView for mock mode

**Files:**
- Modify: `chottoshigoto/Features/Settings/SettingsView.swift`
- Modify: `chottoshigoto/Features/Home/AppPickerView.swift`

**Interfaces:**
- Consumes: `ProtectionService` protocol, `ScreenTimeProtectionService` type (for casting in Release)

- [ ] **Step 1: Update SettingsView with conditional compilation**

Replace the entire content of `chottoshigoto/Features/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(SessionService.self) private var sessionService

    var body: some View {
        NavigationStack {
            List {
                // Protection Section
                Section {
                    #if DEBUG
                    mockProtectionRow
                    #else
                    realProtectionSection
                    #endif
                } header: {
                    Text("Protection")
                } footer: {
                    Text("Select apps to block during focus sessions.")
                }

                // Version
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Mock Protection (DEBUG)

    private var mockProtectionRow: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .foregroundStyle(Color.chottoSage)

            VStack(alignment: .leading, spacing: 2) {
                Text("App Protection")
                    .font(.system(size: 16, weight: .medium))
                Text("Mock active - no real blocking")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.chottoSage)
        }
    }

    // MARK: - Real Protection (Release)

    #if !DEBUG
    @State private var showAppPicker = false
    @State private var needsAuthorization = false
    @State private var newWhitelistBundleId = ""

    private var protection: ScreenTimeProtectionService? {
        sessionService.protection as? ScreenTimeProtectionService
    }

    private var realProtectionSection: some View {
        Group {
            HStack {
                Image(systemName: protection?.isAuthorized == true ? "shield.checkered" : "shield")
                    .foregroundStyle(protection?.isAuthorized == true ? Color.chottoSage : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("App Protection")
                        .font(.system(size: 16, weight: .medium))
                    Text(protection?.selectedApps.isEmpty == true ? "No apps selected" : "\(protection?.selectedApps.count ?? 0) apps blocked")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await authorizeAndPick()
                    }
                } label: {
                    Text(protection?.isAuthorized == true ? "Change" : "Set up")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Whitelist
            ForEach(protection?.whitelistedApps ?? [], id: \.self) { bundleId in
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(Color.chottoSage)
                    Text(bundleIdForDisplay(bundleId))
                        .font(.system(size: 14))
                    Spacer()
                    Button {
                        protection?.removeFromWhitelist(bundleId: bundleId)
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                }
            }

            HStack {
                TextField("Bundle ID (e.g. com.pagerduty.PagerDuty)", text: $newWhitelistBundleId)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    guard !newWhitelistBundleId.isEmpty else { return }
                    protection?.addToWhitelist(bundleId: newWhitelistBundleId)
                    newWhitelistBundleId = ""
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.chottoSage)
                }
                .disabled(newWhitelistBundleId.isEmpty)
            }
        }
    }

    private func authorizeAndPick() async {
        guard let protection else { return }
        do {
            try await protection.requestAuthorization()
            showAppPicker = true
        } catch {
            needsAuthorization = true
        }
    }

    private func bundleIdForDisplay(_ bundleId: String) -> String {
        let known: [String: String] = [
            "com.pagerduty.PagerDuty": "PagerDuty",
            "com.slack.Slack": "Slack",
            "com.apple.mobilephone": "Phone",
            "com.apple.MobileSMS": "Messages",
            "com.apple.mobilemail": "Mail",
        ]
        return known[bundleId] ?? bundleId
    }
    #endif
}

#Preview {
    SettingsView()
        .environment(SessionService(protection: MockProtectionService()))
}
```

- [ ] **Step 2: Update AppPickerView with conditional compilation**

Replace the entire content of `chottoshigoto/Features/Home/AppPickerView.swift`:

```swift
import SwiftUI

#if !DEBUG
import FamilyControls
import ManagedSettings

struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection = FamilyActivitySelection()

    var onSelect: (FamilyActivitySelection) -> Void

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Block Apps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            onSelect(selection)
                            dismiss()
                        }
                    }
                }
        }
    }
}
#endif
```

- [ ] **Step 3: Commit**

```bash
git add chottoshigoto/Features/Settings/SettingsView.swift chottoshigoto/Features/Home/AppPickerView.swift
git commit -m "feat: conditional compilation for SettingsView and AppPickerView mock mode"
```

---

### Task 6: Build verification and fix remaining references

**Files:**
- May modify: any file with remaining `FocusProtectionService` references

**Interfaces:**
- Consumes: all previous tasks

- [ ] **Step 1: Search for remaining FocusProtectionService references**

```bash
grep -r "FocusProtectionService" chottoshigoto/ --include="*.swift"
```

Any remaining references need to be updated to `ScreenTimeProtectionService` or removed.

- [ ] **Step 2: Search for remaining direct FamilyControls imports in non-protected files**

```bash
grep -r "import FamilyControls" chottoshigoto/ --include="*.swift"
grep -r "import ManagedSettings" chottoshigoto/ --include="*.swift"
```

These should only appear in `ScreenTimeProtectionService.swift` and `AppPickerView.swift` (inside `#if !DEBUG`).

- [ ] **Step 3: Update Preview providers**

Check all `#Preview` blocks that create `SessionService()` — they need to pass a `ProtectionService`:

```bash
grep -r "SessionService()" chottoshigoto/ --include="*.swift"
```

Update any `SessionService()` to `SessionService(protection: MockProtectionService())`.

- [ ] **Step 4: Run build verification**

```bash
xcodebuild -project chottoshigoto.xcodeproj -scheme chottoshigoto -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: BUILD SUCCEEDED. If build fails, fix compile errors.

- [ ] **Step 5: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: resolve build issues from ProtectionService abstraction"
```
