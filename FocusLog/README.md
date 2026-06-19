# FocusLog

A macOS focus session tracker. Set a topic, choose a duration (15–90 min), start the timer, then log each session with notes when done. Completed and manually-stopped sessions are shown in your history with duration and timestamps. Data is saved to `~/Library/Application Support/FocusLog/sessions.json`.

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set the product name to **FocusLog**, language **Swift**, interface **SwiftUI**
3. Delete the default `ContentView.swift` and replace with the files from this folder:
   - `FocusLogApp.swift`
   - `Models.swift`
   - `ContentView.swift`
4. Set Deployment Target to **macOS 13.0** or later
5. Build & Run (⌘R)
