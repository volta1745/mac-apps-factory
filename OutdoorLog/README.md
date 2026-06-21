# OutdoorLog

A macOS app for tracking daily time spent outdoors. Log each outing with activity type, weather conditions, duration, and a refreshment rating. View today's progress toward a 30-minute outdoor goal alongside a 7-day average.

## Features

- Log outdoor sessions: activity, weather, duration, and 1–5 refreshment rating
- Daily goal ring showing progress toward 30 minutes outside
- 7-day average and all-time outing count
- Filter history by activity type
- Data persisted to `~/Library/Application Support/OutdoorLog/entries.json`

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set language to Swift, interface to SwiftUI
3. Delete the generated `ContentView.swift`
4. Drag all `.swift` files from this folder into the Xcode project
5. Set minimum deployment target to macOS 13.0
6. Build and run (⌘R)
