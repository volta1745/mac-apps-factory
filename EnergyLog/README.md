# EnergyLog

Track your personal energy levels throughout the day. Log how energized you feel (1 = Exhausted → 5 = Peak), tag contributing factors (Good Sleep, Exercise, Stress, etc.), and review your energy arc over time.

## Features

- **Log Energy** — pick a level 1–5 with emoji indicators, select contributing factors, add a note
- **Today** — summary card (avg, check-in count, peak, low), bar chart arc, timestamped timeline
- **History** — all entries grouped by day, filter by energy level, swipe-to-delete
- **Stats** — overall average, distribution bar chart, top factors, 7-day breakdown

## Data Storage

Entries are saved to `~/Library/Application Support/EnergyLog/entries.json`.

## How to Build

1. Open Xcode → File → New → Project → macOS → App
2. Set the product name to **EnergyLog**, language **Swift**, interface **SwiftUI**
3. Delete the generated `ContentView.swift` and `<AppName>App.swift`
4. Drag all `.swift` files from this folder into the Xcode project (check "Copy items if needed")
5. Set Deployment Target to **macOS 13.0** or later
6. Build & Run (⌘R)
