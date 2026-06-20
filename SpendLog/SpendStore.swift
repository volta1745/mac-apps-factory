import Foundation
import Combine

final class SpendStore: ObservableObject {
    @Published var entries: [SpendEntry] = []
    @Published var dailyBudget: Double = 50.0 {
        didSet { UserDefaults.standard.set(dailyBudget, forKey: budgetKey) }
    }

    private let entriesKey = "spendlog_entries_v1"
    private let budgetKey  = "spendlog_budget_v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([SpendEntry].self, from: data) {
            entries = decoded
        }
        let saved = UserDefaults.standard.double(forKey: budgetKey)
        if saved > 0 { dailyBudget = saved }
    }

    func add(_ entry: SpendEntry) {
        entries.insert(entry, at: 0)
        persist()
    }

    func delete(_ entry: SpendEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    var todayEntries: [SpendEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.date) }
    }

    var todayTotal: Double {
        todayEntries.reduce(0) { $0 + $1.amount }
    }

    var groupedByDay: [(key: Date, value: [SpendEntry])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) { cal.startOfDay(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }
    }

    var allTimeTotal: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
}
