# VoiceLog

A macOS vocal health diary for singers, teachers, podcasters, and public speakers.

## Features

- Log every voice session with type, duration, and vocal strain level (1–5)
- Track whether you warmed up and stayed hydrated
- Today's stats: session count, total voice time, average strain
- Filter history by session type
- Persistent storage in `~/Library/Application Support/VoiceLog/`

## How to Build

1. Open Xcode → File → New → Project → macOS App
2. Set the product name to **VoiceLog** and interface to **SwiftUI**
3. Replace the generated files with `VoiceLogApp.swift`, `VoiceEntry.swift`, and `ContentView.swift`
4. Add all three `.swift` files to the target
5. Set Deployment Target to **macOS 13.0**
6. Build & Run (⌘R)
