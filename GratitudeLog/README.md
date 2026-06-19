# GratitudeLog

A macOS app for logging daily gratitude entries. Record what you're grateful for, tag it by category (Family, Friends, Work, Health, Nature, Learning), and optionally add a brief reflection on why it matters. Track your daily streak and see entries grouped by day.

## Features

- Add gratitude entries with category tags and optional reflections
- Filter the history list by category
- Daily streak tracker and all-time entry count
- Data stored in `~/Library/Application Support/GratitudeLog/entries.json`

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set the language to **Swift** and interface to **SwiftUI**
3. Replace the generated files with the `.swift` files in this folder:
   - `GratitudeLogApp.swift`
   - `GratitudeEntry.swift`
   - `GratitudeStore.swift`
   - `ContentView.swift`
4. Set the deployment target to **macOS 13.0** or later
5. Build & Run (⌘R)
