# WaterLog

A macOS app to track your daily water intake. Log every drink, set a personal hydration goal, and review your history day by day.

## Features

- Quick-add buttons for common amounts (150, 200, 250, 350, 500 mL)
- Custom amount entry with optional notes
- Live progress bar showing today's intake vs. your daily goal
- Per-day history grouped by date with daily totals
- Adjustable daily goal (default 2000 mL)
- Data persisted to `~/Library/Application Support/WaterLog/entries.json`

## How to Build

1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**, name it `WaterLog`
3. Delete the auto-generated Swift files Xcode creates
4. Drag all four `.swift` files from this folder into the project:
   - `WaterLogApp.swift`
   - `Models.swift`
   - `ContentView.swift`
5. Set **Deployment Target** to macOS 13.0 or later
6. Build & Run (⌘R)
