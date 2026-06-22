# ScreenLog

A macOS app for logging and reflecting on your daily screen time. Log each app or website session, categorize it, and mark it as mindful (intentional) or mindless (automatic). A live progress ring tracks your usage against a personal daily limit.

## Features

- Log screen sessions with app/website name, category, duration, and purpose
- Categories: Social Media, Work, Entertainment, Gaming, News, Learning, Shopping
- Mark sessions as Mindful or Mindless to build self-awareness
- Today view with usage ring, mindful vs. mindless totals, and per-category breakdown
- History view with search, category filter, and purpose filter
- Configurable daily screen time limit
- Data persisted to `~/Library/Application Support/ScreenLog/sessions.json`

## How to Build

1. Open Xcode
2. File → New → Project → macOS → App
3. Set the product name to **ScreenLog**, interface **SwiftUI**, language **Swift**
4. Delete the default `ContentView.swift` and `<AppName>App.swift` files
5. Drag all `.swift` files from this folder into the Xcode project
6. Set the minimum deployment target to **macOS 13.0**
7. Build and run (⌘R)
