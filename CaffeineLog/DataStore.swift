import Foundation
import Combine

class DataStore: ObservableObject {
    @Published var entries: [DrinkEntry] = []

    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = support.appendingPathComponent("CaffeineLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        fileURL = appDir.appendingPathComponent("entries.json")
        load()
    }

    func add(_ entry: DrinkEntry) {
        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        save()
    }

    func delete(at offsets: IndexSet, in section: [DrinkEntry]) {
        let idsToRemove = offsets.map { section[$0].id }
        entries.removeAll { idsToRemove.contains($0.id) }
        save()
    }

    var todayEntries: [DrinkEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.timestamp) }
    }

    var todayTotalMg: Int {
        todayEntries.reduce(0) { $0 + $1.caffeineMg }
    }

    func entries(for date: Date) -> [DrinkEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
    }

    var distinctDays: [Date] {
        let cal = Calendar.current
        var seen = Set<DateComponents>()
        var days: [Date] = []
        for entry in entries {
            let components = cal.dateComponents([.year, .month, .day], from: entry.timestamp)
            if seen.insert(components).inserted {
                days.append(cal.startOfDay(for: entry.timestamp))
            }
        }
        return days.sorted(by: >)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([DrinkEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.timestamp > $1.timestamp }
    }
}
