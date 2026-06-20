import Foundation
import Combine

final class DataStore: ObservableObject {
    @Published var entries: [EnergyEntry] = []

    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("EnergyLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("entries.json")
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([EnergyEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func addEntry(_ entry: EnergyEntry) {
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        save()
    }

    func delete(_ entry: EnergyEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    var todayEntries: [EnergyEntry] {
        entries
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    var todayAverage: Double? {
        let t = todayEntries
        guard !t.isEmpty else { return nil }
        return Double(t.map(\.level).reduce(0, +)) / Double(t.count)
    }

    struct DayGroup: Identifiable {
        let id: Date
        var date: Date { id }
        let entries: [EnergyEntry]
    }

    var entriesByDay: [DayGroup] {
        let cal = Calendar.current
        var grouped: [Date: [EnergyEntry]] = [:]
        for e in entries {
            let day = cal.startOfDay(for: e.date)
            grouped[day, default: []].append(e)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { DayGroup(id: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
    }

    var allTimeAverage: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.level).reduce(0, +)) / Double(entries.count)
    }

    var weekEntries: [EnergyEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return entries.filter { $0.date >= cutoff }
    }
}
