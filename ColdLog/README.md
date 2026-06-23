# ColdLog

A macOS app for logging cold exposure sessions — cold showers, ice baths, cold plunges, and outdoor cold swimming. Track duration, water temperature, and your mood before vs. after each session to build a consistent cold therapy habit and see how it affects your wellbeing.

## Features

- Log sessions: type, duration, temperature (°C), mood before/after (1–5)
- Mood delta — instantly see how much each session lifted your mood
- Day streak counter and longest-session stat
- Filter history by exposure type
- Data persisted to `~/Library/Application Support/ColdLog/sessions.json`

## How to build

1. Open **Xcode** → **File → New → Project** → macOS → **App**
2. Set product name to `ColdLog`, language `Swift`, interface `SwiftUI`
3. Delete the auto-generated `ContentView.swift`
4. Drag all four `.swift` files from this folder into the Xcode project (check *Copy items if needed*)
5. Set **Minimum Deployments** to **macOS 13.0**
6. Run with ⌘R
