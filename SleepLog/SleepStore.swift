import Foundation

class SleepStore: ObservableObject {
    @Published var entries: [SleepEntry] = []

    private var fileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("SleepLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }

    init() { load() }

    func add(_ entry: SleepEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Stats helpers

    var last7Entries: [SleepEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return entries.filter { $0.wakeTime >= cutoff }
    }

    var avgHoursLast7: Double? {
        let e = last7Entries
        guard !e.isEmpty else { return nil }
        return Double(e.map(\.durationMinutes).reduce(0, +)) / Double(e.count) / 60.0
    }

    var avgQualityLast7: Double? {
        let e = last7Entries
        guard !e.isEmpty else { return nil }
        return Double(e.map(\.quality).reduce(0, +)) / Double(e.count)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SleepEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
