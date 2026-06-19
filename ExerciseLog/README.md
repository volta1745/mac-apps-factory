# ExerciseLog

A macOS app for logging workout and exercise sessions. Track your activity type, duration, and intensity, and see weekly stats and a daily streak at a glance.

## Features

- Log workouts with type (Running, Cycling, Strength, HIIT, Swimming, Yoga, Walking, Other), duration (5–300 min), and intensity (Easy / Moderate / Hard)
- Weekly stats bar: session count, total minutes, current streak
- Filter history by workout type
- Delete entries with right-click → Delete or swipe
- Data persists to `~/Library/Application Support/ExerciseLog/workouts.json`

## How to build

1. Open **Xcode** → **File → New → Project**
2. Choose **macOS → App**, set language to **Swift**, interface to **SwiftUI**
3. Replace the generated `ContentView.swift` with the files in this folder
4. Add all `.swift` files from this folder to the Xcode target
5. Set the deployment target to **macOS 13.0** or later
6. Build and run (⌘R)
