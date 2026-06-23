# NapLog

A macOS app for logging power nap and rest sessions throughout the day.

## Features

- Log naps with type (Power Nap, Coffee Nap, Full Cycle, Micro Nap, Yoga Nidra)
- Record duration, ease of falling asleep, and post-nap alertness (1–5 stars)
- Track today's nap count, average duration, average alertness, and best nap time of day
- Filter history by nap type and search by keyword
- Data stored in `~/Library/Application Support/NapLog/entries.json`

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set the product name to `NapLog`, interface to `SwiftUI`, language to `Swift`
3. Replace the generated files with the `.swift` files from this folder
4. Set the deployment target to macOS 13.0+
5. Build and run (⌘R)
