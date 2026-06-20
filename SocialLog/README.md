# SocialLog

A macOS app for logging social interactions and tracking your social battery.

Record every conversation, call, or meeting — who you connected with, how long it lasted, what type of interaction it was, and how it left you feeling. Over time, SocialLog reveals which interactions energize you and which drain you.

## Features

- Log interactions: person/group name, type (in-person / phone / video / text / group event), duration, and energy impact (1–5 scale)
- Today's stats bar: interaction count, total time, and average energy impact
- Filter by interaction type with one click
- Search by name or notes
- Colour-coded energy indicators (red → teal)
- Data persisted to `~/Library/Application Support/SocialLog/entries.json`

## How to build

1. Open Xcode → File → New → Project → macOS App
2. Name it **SocialLog**, set interface to **SwiftUI**, language to **Swift**, minimum deployment **macOS 13**
3. Delete the auto-generated `ContentView.swift`
4. Drag all four `.swift` files from this folder into the project (replacing the existing entry point):
   - `SocialLogApp.swift`
   - `ContentView.swift`
   - `AddEntryView.swift`
   - `SocialEntry.swift`
5. Build & Run (⌘R)
