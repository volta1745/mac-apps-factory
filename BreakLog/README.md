# BreakLog

A macOS app that logs your work-break quality throughout the day — track break type, duration, and how refreshed you feel afterwards.

## Features

- Log breaks by type: Micro-break, Screen-free, Walk, Stretch, Lunch, Power nap, Fresh air
- Quick-select duration presets (5, 10, 15, 20, 30, 45, 60 min) or use a stepper
- Rate refreshment level 1–5 stars after each break
- Today's stats bar: break count, total break minutes, average refreshment
- Filter history by break type in the sidebar
- Persistent storage in `~/Library/Application Support/BreakLog/entries.json`

## How to Build

1. Open Xcode → File → New → Project
2. Choose **macOS → App**
3. Set **Interface** to SwiftUI, **Language** to Swift
4. Replace the generated files (or add alongside) with these source files:
   - `BreakLogApp.swift`
   - `BreakEntry.swift`
   - `BreakStore.swift`
   - `AddBreakView.swift`
   - `ContentView.swift`
5. Set the deployment target to **macOS 13.0** or later
6. Build & Run (⌘R)
