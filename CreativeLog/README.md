# CreativeLog

A macOS app for logging creative work sessions — writing, music, drawing, photography, design, coding, crafts, and more.

## Features

- Log each creative session with type, project name, duration (5 min – 5 hr), and creative flow level (1–5)
- Add optional notes for each session
- Browse history grouped by day with search and type filtering
- View stats: total sessions, total hours, day streak, average flow level, and a 7-day activity chart
- Time breakdown by creative type and top projects by total time
- Data persisted to `~/Library/Application Support/CreativeLog/sessions.json`

## How to Build

1. Open Xcode
2. File → New → Project → macOS → App
3. Set Product Name to **CreativeLog**, interface to **SwiftUI**, language to **Swift**
4. Delete the auto-generated `ContentView.swift`
5. Drag all `.swift` files from this folder into the Xcode project (check "Copy items if needed")
6. In the target's General settings, set Minimum Deployments to **macOS 13.0**
7. Build and run (⌘R)

## Requirements

- macOS 13.0+
- Xcode 14+
