# PostureLog

A macOS app that logs posture checks throughout your workday. Rate your posture (Good / Fair / Poor), select affected body areas, record your discomfort level and any corrective action taken, and review a full timestamped history with daily stats.

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set the language to **Swift** and interface to **SwiftUI**
3. Set the minimum deployment target to **macOS 13.0**
4. Delete the default `ContentView.swift` Xcode creates
5. Drag these files into the project:
   - `PostureLogApp.swift`
   - `Models.swift`
   - `ContentView.swift`
6. Build & Run (⌘R)

Data is saved automatically to `~/Library/Application Support/PostureLog/entries.json`.
