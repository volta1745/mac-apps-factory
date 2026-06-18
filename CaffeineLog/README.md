# CaffeineLog

A macOS app to track your daily coffee, tea, and caffeine intake.

## Features

- Log any drink (espresso, drip coffee, matcha, energy drinks, custom) with caffeine amount
- See today's total caffeine vs. the 400 mg daily recommended limit with a live progress bar
- Browse full history grouped by day with per-day totals
- Persists data to `~/Library/Application Support/CaffeineLog/entries.json`

## How to Build

1. Open **Xcode** → **File** → **New** → **Project**
2. Choose **macOS → App**, set language to **Swift**, interface to **SwiftUI**
3. Delete the auto-generated `ContentView.swift`
4. Drag all `.swift` files from this folder into the Xcode project (make sure "Copy items if needed" is checked)
5. Set the deployment target to **macOS 13.0** or later
6. Press **⌘R** to build and run

## Requirements

- Xcode 15+
- macOS 13 Ventura or later
