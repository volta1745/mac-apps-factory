# DreamLog

A macOS dream journal app for recording and analyzing your dreams each morning.

## Features

- Log dreams with title, notes, type (Normal/Lucid/Recurring/Nightmare/Vivid/Prophetic/Abstract), emotional tone, clarity rating, and sleep quality
- Journal view with search and sidebar filters by dream type or emotion
- Insights tab with stats (average clarity, average sleep quality, most common type), type and emotion breakdowns with bar charts, and a 7-night activity grid
- Data saved automatically to `~/Library/Application Support/DreamLog/dreams.json`

## How to build

1. Open Xcode → File → New → Project
2. Choose **macOS → App**, set language to **Swift**, interface to **SwiftUI**
3. Replace the generated `ContentView.swift` with the one from this folder
4. Add `DreamLogApp.swift`, `DreamModel.swift`, `AddDreamView.swift`, and `ContentView.swift` to the project (delete the default `<AppName>App.swift` Xcode created)
5. Set the deployment target to **macOS 13.0** or later
6. Build and run (⌘R)

## Requirements

- macOS 13 Ventura or later
- Xcode 15+
