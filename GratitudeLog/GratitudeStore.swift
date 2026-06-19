import Foundation
import Combine

class GratitudeStore: ObservableObject {
    @Published var entries: [GratitudeEntry] = []

    private let storageURL: URL

    init() {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("GratitudeLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storageURL = dir.appendingPathComponent("entries.json")
        load()
    }

    func add(text: String, category: GratitudeCategory, reflection: String) {
        let entry = GratitudeEntry(
            text: text,
            category: category,
            reflection: reflection,
            date: Date()
        )
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: GratitudeEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    // MARK: - Computed stats

    var todayCount: Int {
        entries.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let entryDays = Set(entries.map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var day = cal.startOfDay(for: Date())
        while entryDays.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    // Returns entries sorted newest-first, grouped by calendar day label.
    func groupedByDay(filtered category: GratitudeCategory?) -> [(label: String, entries: [GratitudeEntry])] {
        let source = category == nil ? entries : entries.filter { $0.category == category }
        let sorted = source.sorted { $0.date > $1.date }

        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .none

        var groups: [(label: String, entries: [GratitudeEntry])] = []
        var indexMap: [String: Int] = [:]

        for entry in sorted {
            let key = df.string(from: entry.date)
            if let idx = indexMap[key] {
                groups[idx].entries.append(entry)
            } else {
                indexMap[key] = groups.count
                groups.append((label: key, entries: [entry]))
            }
        }
        return groups
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([GratitudeEntry].self, from: data)
        else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
