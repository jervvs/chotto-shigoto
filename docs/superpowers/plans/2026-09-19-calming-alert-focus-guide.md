# Calming Alert + Focus Guide Overhaul — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a calming haptic + chime when the focus timer completes, and replace the Focus Automation Guide with a Shortcut-chaining approach.

**Architecture:** Two independent changes — one in the session state machine (alert), one in a SwiftUI view (guide). No shared code between them.

**Tech Stack:** Swift, SwiftUI, AVFoundation (AudioServices), UIKit (UIImpactFeedbackGenerator)

## Global Constraints

- iOS 26.3+, Swift 6.0, SwiftUI
- English-first UI with Japanese accents
- No custom audio files — use iOS system sounds only
- Accent color: sage green (`Color.chottoSage`), never `.orange`

---

### Task 1: Add completion alert to SessionService

**Files:**
- Modify: `chottoshigoto/Session/SessionService.swift:101-116`

**Interfaces:**
- Consumes: existing `completeSession()` method
- Produces: `playCompletionFeedback()` private method, called from `completeSession()`

- [x] **Step 1: Add import for AudioServices**

At the top of `SessionService.swift`, the file already imports `Foundation`, `Combine`, `SwiftData`, and `os`. Add `import AVFoundation` (which contains `AudioServicesPlaySystemSound`).

```swift
import Foundation
import Combine
import SwiftData
import os
import AVFoundation
```

- [x] **Step 2: Add playCompletionFeedback method**

Add this private method to `SessionService`, in the Timer section (after `stopTimer()`):

```swift
private func playCompletionFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    AudioServicesPlaySystemSound(1025)
}
```

Note: `UIImpactFeedbackGenerator` is from UIKit. Add `import UIKit` at the top of the file.

- [x] **Step 3: Call playCompletionFeedback from completeSession()**

In `completeSession()`, add the call at the top of the method body, before the `guard` statement:

```swift
func completeSession() {
    playCompletionFeedback()
    guard case .active(let session) = state else { return }
    stopTimer()
    // ... rest unchanged
}
```

- [x] **Step 4: Build and verify**

Run: `xcodebuild -project chottoshigoto.xcodeproj -scheme chottoshigoto -destination 'platform=iOS Simulator,name=iPhone 17' build`

Expected: Build succeeds with no errors.

- [x] **Step 5: Commit**

```bash
git add chottoshigoto/Session/SessionService.swift
git commit -m "feat: add calming haptic + chime on session completion"
```

---

### Task 2: Rewrite FocusAutomationGuide

**Files:**
- Rewrite: `chottoshigoto/Features/Settings/FocusAutomationGuide.swift`

**Interfaces:**
- Consumes: `Color.chottoSage`, `Color.chottoCream` from DesignSystem
- Produces: updated guide view accessible from Settings

- [x] **Step 1: Replace the entire FocusAutomationGuide body**

Replace the full content of `FocusAutomationGuide.swift` with:

```swift
import SwiftUI

struct FocusAutomationGuide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Automation")
                        .font(.system(size: 28, weight: .light, design: .serif))

                    Text("Create a Shortcut that starts your Chotto session and automatically turns on a Focus mode until the session ends.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Chotto exposes \"Start Chotto\" and \"Get Chotto End Time\" actions to Shortcuts. Chain them with a Focus action to automatically reduce interruptions during your session.")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                // Flow diagram
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shortcut flow")
                        .font(.system(size: 17, weight: .semibold))

                    VStack(spacing: 0) {
                        FlowStep(icon: "timer", title: "Start Chotto", subtitle: "Starts your focus session")
                        FlowConnector()
                        FlowStep(icon: "arrow.up.forward.app", title: "Open Chotto", subtitle: "Brings app to foreground")
                        FlowConnector()
                        FlowStep(icon: "clock", title: "Get Chotto End Time", subtitle: "Returns session end date")
                        FlowConnector()
                        FlowStep(icon: "moon.zzz", title: "Set Focus", subtitle: "On until end time")
                    }
                    .padding(16)
                    .background(Color.chottoSage.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    Text("Setup steps")
                        .font(.system(size: 17, weight: .semibold))

                    GuideStep(
                        number: "1",
                        title: "Open Shortcuts and create a new Shortcut",
                        detail: "Tap \"+\" in the Shortcuts app to create a new Shortcut."
                    )

                    GuideStep(
                        number: "2",
                        title: "Add \"Start Chotto\"",
                        detail: "Search for \"Start Chotto\" and add it. This starts your focus session."
                    )

                    GuideStep(
                        number: "3",
                        title: "Add \"Open chottoshigoto\"",
                        detail: "Search for \"Open App\" and select Chotto. This ensures the app is in the foreground."
                    )

                    GuideStep(
                        number: "4",
                        title: "Add \"Get Chotto End Time\"",
                        detail: "Search for \"Get Chotto End Time\" and add it. This returns the session's end date."
                    )

                    GuideStep(
                        number: "5",
                        title: "Add \"Set Focus\"",
                        detail: "Search for \"Set Focus\" and choose your Focus mode (e.g., Reduce Interruptions). Set it to turn On."
                    )

                    GuideStep(
                        number: "6",
                        title: "Set the Focus duration",
                        detail: "Tap the time parameter in the Focus action, then select the \"Get Chotto End Time\" variable. Your Focus will automatically turn off when the session ends."
                    )
                }

                // What Chotto exposes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chotto actions in Shortcuts")
                        .font(.system(size: 17, weight: .semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        ActionRow(
                            icon: "timer",
                            name: "Start Chotto",
                            description: "Opens Chotto and starts a focus session with your default timer"
                        )

                        Divider()

                        ActionRow(
                            icon: "clock",
                            name: "Get Chotto End Time",
                            description: "Returns the end time of the current active session"
                        )
                    }
                    .padding(12)
                    .background(Color.chottoSage.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()
            }
            .padding(20)
        }
        .background(Color.chottoCream.ignoresSafeArea())
        .navigationTitle("Focus Automation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views

private struct FlowStep: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.chottoSage)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct FlowConnector: View {
    var body: some View {
        HStack {
            Spacer()
                .frame(width: 36)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.chottoSage.opacity(0.3))
                    .frame(width: 1, height: 12)
            }
            Spacer()
        }
    }
}

private struct ActionRow: View {
    let icon: String
    let name: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.chottoSage)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct GuideStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.chottoSage)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FocusAutomationGuide()
    }
}
```

- [x] **Step 2: Build and verify**

Run: `xcodebuild -project chottoshigoto.xcodeproj -scheme chottoshigoto -destination 'platform=iOS Simulator,name=iPhone 17' build`

Expected: Build succeeds with no errors.

- [x] **Step 3: Commit**

```bash
git add chottoshigoto/Features/Settings/FocusAutomationGuide.swift
git commit -m "feat: rewrite focus automation guide with Shortcut-chaining approach"
```
