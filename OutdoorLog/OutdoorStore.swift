import Foundation

class OutdoorStore: ObservableObject {
    @Published var entries: [OutdoorEntry] = []

    private let saveURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("OutdoorLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: OutdoorEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Stats

    var todayEntries: [OutdoorEntry] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayMinutes: Int {
        todayEntries.reduce(0) { $0 + $1.durationMinutes }
    }

    // Minutes per day for the past 7 days (index 0 = today)
    var weeklyMinutes: [Int] {
        let cal = Calendar.current
        return (0..<7).map { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { return 0 }
            return entries
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationMinutes }
        }
    }

    var weeklyAvgMinutes: Int {
        let total = weeklyMinutes.reduce(0, +)
        return total / 7
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([OutdoorEntry].self, from: data) else { return }
        entries = decoded
    }
}
