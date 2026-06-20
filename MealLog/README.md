# MealLog

A macOS meal diary app that records everything you eat throughout the day. Log each meal or snack with what you ate, hunger level before eating, and satisfaction afterwards. Review your eating history grouped by day and filter by meal type.

## Features

- Log meals and snacks with food descriptions, hunger (1–5), and satisfaction (1–5)
- Five meal types: Breakfast, Lunch, Dinner, Snack, Drink
- Today's meal count, all-time total, and 7-day average satisfaction stats
- History grouped by day, filterable by meal type
- Data persisted to `~/Library/Application Support/MealLog/entries.json`

## How to build

1. Open Xcode → File → New → Project → macOS → App
2. Set the product name to **MealLog**, interface **SwiftUI**, language **Swift**
3. Replace the generated files and add all `.swift` files from this folder to the project target
4. Set the minimum deployment target to **macOS 13.0**
5. Build and run (⌘R)
