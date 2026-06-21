# SupplementLog

A macOS app that tracks your daily vitamin and supplement intake. Define your personal supplement stack, check off each item as you take it, and review your compliance history.

## Features

- **My Stack** — Add supplements with name and dosage (quick presets or custom entry)
- **Today checklist** — Tap to mark each supplement as taken; tap again to undo
- **Progress bar** — Live visual of today's completion
- **Streak counter** — Consecutive days with any supplements logged
- **History** — Full log of every intake, grouped by date
- **Persistence** — Data saved to `~/Library/Application Support/SupplementLog/`

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set product name to **SupplementLog**, language **Swift**, interface **SwiftUI**
3. Delete the auto-generated `ContentView.swift` (or replace it)
4. Drag all `.swift` files from this folder into the Xcode project (check "Copy items if needed")
5. In the project target, set **Minimum Deployments** to **macOS 13.0**
6. Build & run (⌘R)
