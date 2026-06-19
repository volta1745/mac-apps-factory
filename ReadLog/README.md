# ReadLog

A macOS app for logging book reading sessions. Track what you read, how many pages you covered, and how long each session lasted. Weekly stats keep you motivated.

## Features

- Log a session: book title, author, page range, time spent, and notes
- Full history list with swipe-to-delete
- Weekly summary: sessions, total pages, total reading time
- Data persisted to `~/Library/Application Support/ReadLog/sessions.json`

## How to build

1. Open Xcode → File → New → Project → macOS App
2. Set the product name to **ReadLog**, language **Swift**, interface **SwiftUI**
3. Delete the auto-generated `ContentView.swift`
4. Drag **ReadLogApp.swift**, **Models.swift**, and **ContentView.swift** into the project
5. Set Deployment Target to **macOS 13.0**
6. Build & Run (⌘R)
