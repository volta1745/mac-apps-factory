# SkillLog

A macOS app for tracking deliberate practice sessions for any skill you're learning — guitar, Spanish, sketching, coding, and more.

## Features

- Add any number of skills across categories (Music, Language, Art, Coding, Sport, Writing)
- Log practice sessions with duration, difficulty rating, and notes
- View per-skill stats: total sessions, total practice time, current daily streak
- Overview dashboard with skill cards and recent activity feed
- Data saved to `~/Library/Application Support/SkillLog/`

## How to Build

1. Open Xcode
2. File → New → Project → macOS → App
3. Name it **SkillLog**, set Interface to **SwiftUI**, Language to **Swift**
4. Delete the auto-generated `ContentView.swift`
5. Drag these files into the Xcode project:
   - `SkillLogApp.swift`
   - `ContentView.swift`
   - `Models.swift`
6. Set Deployment Target to **macOS 13.0** or later
7. Build & Run (⌘R)
