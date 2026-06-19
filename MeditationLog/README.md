# MeditationLog

A macOS app to log mindfulness and meditation sessions. Track duration, meditation type, and calmness level before and after each session to observe how your practice affects your mental state over time.

## Features

- Log sessions with type, duration (1–120 min), and calmness level (1–5) before and after
- Six meditation types: Breathing, Body Scan, Visualization, Loving-Kindness, Walking, Sound/Mantra
- At-a-glance stats: total sessions, total time, current daily streak, and average calmness improvement
- Filter session history by meditation type
- Per-session detail view with notes
- Data persisted to `~/Library/Application Support/MeditationLog/sessions.json`

## How to Build

1. Open Xcode → File → New → Project
2. Choose **macOS → App**, set language to **Swift**, interface to **SwiftUI**
3. Delete the default `ContentView.swift` and `<AppName>App.swift` files Xcode creates
4. Drag all four `.swift` files from this folder into the Xcode project:
   - `MeditationLogApp.swift`
   - `MeditationSession.swift`
   - `AddSessionView.swift`
   - `ContentView.swift`
5. Set **Minimum Deployment Target** to macOS 13.0
6. Build and run (⌘R)

## Requirements

- macOS 13.0 Ventura or later
- Xcode 15+
