import Foundation

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case drink = "Drink"

    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch:     return "☀️"
        case .dinner:    return "🌙"
        case .snack:     return "🍎"
        case .drink:     return "☕️"
        }
    }
}

struct MealEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var mealType: MealType
    var foods: String
    var hungerBefore: Int   // 1–5
    var satisfactionAfter: Int // 1–5
    var notes: String

    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

@MainActor
class MealStore: ObservableObject {
    @Published var entries: [MealEntry] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("MealLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: MealEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet, from group: [MealEntry]) {
        let idsToDelete = offsets.map { group[$0].id }
        entries.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    func entries(for dayKey: String) -> [MealEntry] {
        entries.filter { $0.dayKey == dayKey }
    }

    var groupedDays: [String] {
        Array(Set(entries.map(\.dayKey))).sorted(by: >)
    }

    var todayCount: Int {
        let key = MealEntry(mealType: .lunch, foods: "", hungerBefore: 3, satisfactionAfter: 3, notes: "").dayKey
        return entries(for: key).count
    }

    var weeklyAvgHunger: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recent = entries.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return 0 }
        return Double(recent.map(\.hungerBefore).reduce(0, +)) / Double(recent.count)
    }

    var weeklyAvgSatisfaction: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recent = entries.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return 0 }
        return Double(recent.map(\.satisfactionAfter).reduce(0, +)) / Double(recent.count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([MealEntry].self, from: data) else { return }
        entries = decoded
    }
}
