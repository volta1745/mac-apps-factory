import Foundation

enum ChoreCategory: String, CaseIterable, Codable {
    case kitchen = "Kitchen"
    case bathroom = "Bathroom"
    case bedroom = "Bedroom"
    case livingRoom = "Living Room"
    case yard = "Yard & Garden"
    case laundry = "Laundry"
    case general = "General"

    var icon: String {
        switch self {
        case .kitchen: return "fork.knife"
        case .bathroom: return "shower"
        case .bedroom: return "bed.double"
        case .livingRoom: return "sofa"
        case .yard: return "leaf"
        case .laundry: return "tshirt"
        case .general: return "house"
        }
    }
}

let commonChores: [String: ChoreCategory] = [
    "Dishes": .kitchen,
    "Wipe counters": .kitchen,
    "Clean stove": .kitchen,
    "Take out trash": .kitchen,
    "Mop floors": .general,
    "Vacuum": .general,
    "Dusting": .general,
    "Clean toilet": .bathroom,
    "Scrub shower/tub": .bathroom,
    "Wash bathroom sink": .bathroom,
    "Make bed": .bedroom,
    "Change sheets": .bedroom,
    "Tidy bedroom": .bedroom,
    "Vacuum living room": .livingRoom,
    "Tidy living room": .livingRoom,
    "Mow lawn": .yard,
    "Water plants": .yard,
    "Weed garden": .yard,
    "Wash clothes": .laundry,
    "Dry & fold laundry": .laundry,
    "Iron clothes": .laundry,
    "Grocery shopping": .general,
    "Organize pantry": .kitchen,
    "Clean microwave": .kitchen,
    "Window cleaning": .general,
]

struct ChoreEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var taskName: String
    var category: ChoreCategory
    var durationMinutes: Int
    var effortLevel: Int
    var notes: String
    var completedAt: Date
}

class ChoreStore: ObservableObject {
    @Published var entries: [ChoreEntry] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ChoreLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: ChoreEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    var todayEntries: [ChoreEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.completedAt) }
    }

    var todayTotalMinutes: Int {
        todayEntries.reduce(0) { $0 + $1.durationMinutes }
    }

    var todayTaskCount: Int { todayEntries.count }

    func weeklyStats() -> (tasks: Int, minutes: Int) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let week = entries.filter { $0.completedAt >= weekAgo }
        return (week.count, week.reduce(0) { $0 + $1.durationMinutes })
    }

    func categoryCounts() -> [(category: ChoreCategory, count: Int)] {
        var counts: [ChoreCategory: Int] = [:]
        for e in entries { counts[e.category, default: 0] += 1 }
        return counts.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([ChoreEntry].self, from: data) {
            entries = decoded
        }
    }
}
