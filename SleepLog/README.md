# SleepLog

A macOS app for tracking sleep duration and quality night by night.

## Features

- Log bedtime and wake-up time for each night
- Rate sleep quality from 1 (Poor) to 5 (Great) with a star picker
- Add optional notes (dreams, disturbances, etc.)
- Summary bar showing 7-day average duration and average quality
- Full chronological history with color-coded quality indicator
- Data persisted to `~/Library/Application Support/SleepLog/entries.json`

## How to build

1. Open **Xcode** → **File** → **New** → **Project**
2. Choose **macOS → App**, name it `SleepLog`, set language to **Swift** and interface to **SwiftUI**
3. Delete the auto-generated `ContentView.swift`
4. Drag all `.swift` files from this folder into the Xcode project (check "Copy items if needed")
5. Set the **Deployment Target** to **macOS 13.0** or later
6. Press **⌘R** to build and run
