# Design: Calming Alert + Focus Automation Guide Overhaul

**Date**: 2026-09-19
**Status**: Approved

## Overview

Two changes to improve the session completion experience and simplify Focus integration guidance:

1. Add a calming haptic + chime alert when a focus session timer completes
2. Replace the Focus Automation Guide with a Shortcut-chaining approach

---

## Change 1: Calming Alert on Timer Completion

### Problem
When the timer hits zero, the app transitions silently to CompletionView. Users may not notice the session ended if they're not looking at the screen.

### Solution
Play a gentle haptic and soft chime at the moment of completion.

### Implementation

**File**: `chottoshigoto/Session/SessionService.swift`

Add two helper methods and call them from `completeSession()`:

```swift
private func playCompletionFeedback() {
    // Haptic: soft/light impact
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()

    // Sound: Tink — a gentle, short chime
    AudioServicesPlaySystemSound(1025)
}
```

Call `playCompletionFeedback()` at the top of `completeSession()`, before state transition.

**Why `completeSession()`**: This is the single path for all session completions (timer expiry, recovery expiry). One call site = consistent behavior.

**Sound choice**: System sound 1025 (`Tink`) is a calm, short chime already available on iOS — no custom audio files needed.

**Haptic choice**: `.light` impact is subtle and pleasant, like a meditation app ending.

### Files Changed
- `chottoshigoto/Session/SessionService.swift` — add `playCompletionFeedback()`, call from `completeSession()`

---

## Change 2: Focus Automation Guide Overhaul

### Problem
The current guide describes a 6-step personal automation approach (trigger on app open/close). This is complex and doesn't match the simpler Shortcut-chaining pattern users actually want.

### Solution
Replace the guide with a Shortcut-chaining approach that matches the user's screenshot:

1. Create a Shortcut
2. Add "Start Chotto" → opens app, starts session
3. Add "Open chottoshigoto" → ensures app is foregrounded
4. Add "Get Chotto End Time" → returns session end date
5. Add "Set Focus" → turn on a Focus mode (e.g., Reduce Interruptions) until the end time variable
6. Run the Shortcut to start your session with Focus

### Implementation

**File**: `chottoshigoto/Features/Settings/FocusAutomationGuide.swift` — full rewrite

Replace the existing content with:

- **Header**: "Focus Automation" title + subtitle explaining the Shortcut approach
- **How it works**: Brief explanation that Chotto exposes intents to Shortcuts, and you can chain them with Focus actions
- **Visual flow**: A text-based chain diagram showing the 4 actions connected:
  ```
  Start Chotto → Open Chotto → Get End Time → Set Focus until End Time
  ```
- **Setup steps**: 6 clear numbered steps matching the screenshot's flow
- **Available actions section**: Lists the two Chotto intents:
  - "Start Chotto" — starts a focus session, returns end time
  - "Get Chotto End Time" — returns end time of active session
- **Tip**: Note that the user can also create a second Shortcut to turn Focus off manually, or let it expire naturally with the "until" time

### Files Changed
- `chottoshigoto/Features/Settings/FocusAutomationGuide.swift` — full rewrite

---

## Testing

- **Alert**: Run a short session (1 min), verify haptic fires and sound plays on completion
- **Guide**: Navigate to Settings → Focus Automation, verify the new guide renders correctly with the Shortcut-chaining steps
