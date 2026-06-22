# FastingLog

A macOS app for tracking intermittent fasting windows.

## Features

- Choose a fasting protocol: 16:8, 18:6, 20:4, OMAD, or a custom goal
- Start/end a fast with a live countdown ring showing progress toward your goal
- See exactly when your goal window will be reached
- Save completed fasts to history with optional notes
- Filter history by protocol
- Sidebar stats: total fasts, goal-met count, current streak, average, and longest fast

## How to Build

1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**, set language to **Swift**, interface to **SwiftUI**
3. Delete the default `ContentView.swift` the template creates
4. Drag all `.swift` files from this folder into the Xcode project (check *Copy items if needed*)
5. Set **Deployment Target** to **macOS 13.0** or later
6. Build & Run (⌘R)

## Data Storage

Fasting entries are saved to:
```
~/Library/Application Support/FastingLog/entries.json
```
An active (in-progress) fast is persisted separately so it survives app restarts.
