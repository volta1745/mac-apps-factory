import Foundation
import Combine

final class BreakStore: ObservableObject {
    @Published private(set) var entries: [BreakEntry] = []

    private let fileURL: URL = {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BreakLog")
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: BreakEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: BreakEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    // MARK: - Today's stats
    var todayEntries: [BreakEntry] {
        let todayKey = BreakEntry(breakType: .micro, durationMinutes: 0, refreshmentLevel: 0, note: "").dayKey
        return entries.filter { $0.dayKey == todayKey }
    }

    var todayBreakCount: Int { todayEntries.count }

    var todayTotalMinutes: Int { todayEntries.reduce(0) { $0 + $1.durationMinutes } }

    var todayAvgRefreshment: Double {
        guard !todayEntries.isEmpty else { return 0 }
        return Double(todayEntries.reduce(0) { $0 + $1.refreshmentLevel }) / Double(todayEntries.count)
    }

    // MARK: - Grouped by day for history
    var groupedEntries: [(key: String, entries: [BreakEntry])] {
        var dict: [String: [BreakEntry]] = [:]
        for e in entries { dict[e.dayKey, default: []].append(e) }
        return dict.keys.sorted(by: >).map { (key: $0, entries: dict[$0]!) }
    }

    // MARK: - Persistence
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        entries = (try? JSONDecoder().decode([BreakEntry].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
