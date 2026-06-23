# ChoreLog

A macOS app for logging household tasks and chores you complete throughout the day.

## Features

- Log any household chore with task name, category, time spent, effort level, and notes
- Quick-pick common chores (dishes, vacuuming, laundry, etc.) with auto-assigned categories
- Today's task count and total time at a glance
- Weekly stats for total tasks and time spent
- Filter history by category (Kitchen, Bathroom, Bedroom, Living Room, Yard, Laundry, General)
- Search across all logged chores
- Effort level (1–5 bolt icons) visualised per entry
- Day-grouped history with per-day task count and total time
- Data persisted to `~/Library/Application Support/ChoreLog/entries.json`

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set the product name to `ChoreLog`, language `Swift`, interface `SwiftUI`
3. Delete the auto-generated `ContentView.swift`
4. Add all `.swift` files from this folder to the Xcode project target
5. Set Deployment Target to **macOS 13.0** or later
6. Build & Run (⌘R)
