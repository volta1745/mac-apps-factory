# BreathLog

A macOS app for logging breathing exercise sessions — box breathing, 4-7-8, Wim Hof, alternate nostril, coherence breathing, and more.

## Features

- Log each session with technique, rounds, duration, stress level before, and calm level after
- Filter history by breathing technique
- Track today's session count and total minutes breathed
- See all-time average calm score and average stress reduction per session
- Data stored in `~/Library/Application Support/BreathLog/sessions.json`

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set the product name to `BreathLog`, language Swift, interface SwiftUI
3. Delete the generated `ContentView.swift`
4. Drag all four `.swift` files from this folder into the Xcode project
5. Set the minimum deployment target to macOS 13.0
6. Build and run (⌘R)
