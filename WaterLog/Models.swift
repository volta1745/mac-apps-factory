import Foundation

struct WaterEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var amountML: Int
    var note: String

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

class WaterStore: ObservableObject {
    @Published var entries: [WaterEntry] = []
    @Published var dailyGoalML: Int = 2000

    private let storageURL: URL
    private let goalsKey = "waterlog.dailyGoal"

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("WaterLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storageURL = dir.appendingPathComponent("entries.json")
        dailyGoalML = UserDefaults.standard.integer(forKey: goalsKey)
        if dailyGoalML == 0 { dailyGoalML = 2000 }
        load()
    }

    var todayEntries: [WaterEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.date) }.sorted { $0.date > $1.date }
    }

    var todayTotalML: Int {
        todayEntries.reduce(0) { $0 + $1.amountML }
    }

    var goalProgress: Double {
        min(Double(todayTotalML) / Double(dailyGoalML), 1.0)
    }

    func add(amountML: Int, note: String = "") {
        let entry = WaterEntry(date: Date(), amountML: amountML, note: note)
        entries.append(entry)
        save()
    }

    func delete(_ entry: WaterEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func setGoal(_ ml: Int) {
        dailyGoalML = ml
        UserDefaults.standard.set(ml, forKey: goalsKey)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([WaterEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
