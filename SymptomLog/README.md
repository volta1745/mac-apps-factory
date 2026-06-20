# SymptomLog

A macOS app for logging physical symptoms throughout the day. Track headaches, fatigue, back pain, and any other recurring symptoms with severity ratings (1–5), body location, and optional notes. Filter history by symptom type and monitor your average severity over time.

## How to build

1. Open Xcode → **File → New → Project → macOS → App**
2. Product name: **SymptomLog** | Interface: SwiftUI | Language: Swift
3. Set deployment target to **macOS 13.0** or later
4. Delete the default `ContentView.swift` and the auto-generated App entry file
5. Drag all four `.swift` files from this folder into the Xcode project navigator (check "Copy items if needed")
6. Build and run (**⌘R**)

Data is saved automatically to `~/Library/Application Support/SymptomLog/entries.json`.
