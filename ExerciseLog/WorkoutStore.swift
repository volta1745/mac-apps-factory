import Foundation

class WorkoutStore: ObservableObject {
    @Published var entries: [WorkoutEntry] = []

    private let saveURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("ExerciseLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("workouts.json")
        load()
    }

    func add(_ entry: WorkoutEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(withIDs ids: Set<UUID>) {
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Stats

    var thisWeekEntries: [WorkoutEntry] {
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return entries.filter { $0.date >= weekStart }
    }

    var weeklyMinutes: Int {
        thisWeekEntries.reduce(0) { $0 + $1.durationMinutes }
    }

    var streak: Int {
        let cal = Calendar.current
        var checkDate = Date()
        var count = 0

        // If today has no entry, start streak check from yesterday
        let todayStart = cal.startOfDay(for: checkDate)
        let todayEnd   = cal.date(byAdding: .day, value: 1, to: todayStart)!
        let hasToday   = entries.contains { $0.date >= todayStart && $0.date < todayEnd }
        if !hasToday {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        for _ in 0..<365 {
            let start = cal.startOfDay(for: checkDate)
            let end   = cal.date(byAdding: .day, value: 1, to: start)!
            if entries.contains(where: { $0.date >= start && $0.date < end }) {
                count += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return count
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: saveURL)
    }

    private func load() {
        guard
            let data    = try? Data(contentsOf: saveURL),
            let decoded = try? JSONDecoder().decode([WorkoutEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
