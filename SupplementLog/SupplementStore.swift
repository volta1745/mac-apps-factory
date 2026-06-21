import Foundation
import SwiftUI

@MainActor
final class SupplementStore: ObservableObject {
    @Published var supplements: [Supplement] = []
    @Published var entries: [IntakeEntry] = []

    private let supplementsURL: URL
    private let entriesURL: URL

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SupplementLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        supplementsURL = dir.appendingPathComponent("supplements.json")
        entriesURL = dir.appendingPathComponent("entries.json")
        load()
    }

    // MARK: - Computed

    var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    var todayEntries: [IntakeEntry] {
        entries.filter { $0.dateKey == todayKey }
    }

    var todayCount: Int {
        Set(todayEntries.map { $0.supplementID }).count
    }

    var totalCount: Int { supplements.count }

    var completionToday: Double {
        guard totalCount > 0 else { return 0 }
        return min(1, Double(todayCount) / Double(totalCount))
    }

    func isTaken(_ supplement: Supplement) -> Bool {
        todayEntries.contains { $0.supplementID == supplement.id }
    }

    func entryFor(_ supplement: Supplement) -> IntakeEntry? {
        todayEntries.first { $0.supplementID == supplement.id }
    }

    var entriesByDate: [(date: String, entries: [IntakeEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.dateKey }
        return grouped
            .map { (date: $0.key, entries: $0.value.sorted { $0.takenAt < $1.takenAt }) }
            .sorted { $0.date > $1.date }
    }

    var currentStreak: Int {
        guard !entries.isEmpty else { return 0 }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let loggedDates = Set(entries.map { $0.dateKey })
        var streak = 0
        var checkDate = Date()
        // If nothing logged today, start counting from yesterday
        if !loggedDates.contains(fmt.string(from: checkDate)) {
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        while true {
            let key = fmt.string(from: checkDate)
            guard loggedDates.contains(key) else { break }
            streak += 1
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            if streak > 365 { break }
        }
        return streak
    }

    // MARK: - Actions

    func markTaken(_ supplement: Supplement) {
        guard !isTaken(supplement) else { return }
        entries.append(IntakeEntry(
            supplementID: supplement.id,
            supplementName: supplement.name,
            supplementDosage: supplement.dosage,
            takenAt: Date()
        ))
        save()
    }

    func unmarkTaken(_ supplement: Supplement) {
        entries.removeAll { $0.supplementID == supplement.id && $0.dateKey == todayKey }
        save()
    }

    func addSupplement(name: String, dosage: String) {
        supplements.append(Supplement(name: name, dosage: dosage.isEmpty ? "—" : dosage))
        save()
    }

    func deleteSupplement(at offsets: IndexSet) {
        let ids = offsets.map { supplements[$0].id }
        supplements.remove(atOffsets: offsets)
        entries.removeAll { ids.contains($0.supplementID) }
        save()
    }

    // MARK: - Persistence

    private func load() {
        if let data = try? Data(contentsOf: supplementsURL),
           let decoded = try? JSONDecoder().decode([Supplement].self, from: data) {
            supplements = decoded
        }
        if let data = try? Data(contentsOf: entriesURL),
           let decoded = try? JSONDecoder().decode([IntakeEntry].self, from: data) {
            entries = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(supplements) { try? data.write(to: supplementsURL) }
        if let data = try? JSONEncoder().encode(entries) { try? data.write(to: entriesURL) }
    }
}
