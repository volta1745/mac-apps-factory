# SpendLog

A macOS app that logs daily purchases with category, amount, and a note, tracks spending against a configurable daily budget with a live ring indicator, and shows a full history grouped by date.

## Features

- Log any purchase: category, amount, optional note, date/time
- Today view: budget ring showing % of daily budget used, category breakdown, per-entry list
- History view: all entries grouped by day with daily totals
- Settings: adjustable daily budget, all-time stats
- Persistence via UserDefaults

## How to build

1. Open Xcode → File → New → Project
2. Choose **macOS → App**, set language to **Swift**, interface to **SwiftUI**
3. Delete the auto-generated `ContentView.swift`
4. Drag all four `.swift` files from this folder into the project (SpendLogApp.swift, SpendEntry.swift, SpendStore.swift, ContentView.swift)
5. Ensure all files are added to the app target
6. Set Deployment Target to **macOS 13.0** or later
7. Build and Run (⌘R)
