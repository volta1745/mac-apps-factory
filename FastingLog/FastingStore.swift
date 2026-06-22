import Foundation
import Combine

class FastingStore: ObservableObject {
    @Published var entries: [FastingEntry] = []
    @Published var activeFast: FastingEntry?
    @Published var selectedProtocol: FastingProtocol = .sixteenEight
    @Published var customGoalHours: Double = 16

    private let saveURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("FastingLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    private let activeURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("FastingLog", isDirectory: true)
        return dir.appendingPathComponent("active.json")
    }()

    init() { load() }

    var currentGoalHours: Double {
        selectedProtocol == .custom ? customGoalHours : selectedProtocol.goalHours
    }

    func startFast() {
        guard activeFast == nil else { return }
        let fast = FastingEntry(
            startTime: Date(),
            endTime: nil,
            protocol_: selectedProtocol,
            goalHours: currentGoalHours,
            notes: ""
        )
        activeFast = fast
        saveActive()
    }

    func endFast(notes: String) {
        guard var fast = activeFast else { return }
        fast.endTime = Date()
        fast.notes = notes
        entries.insert(fast, at: 0)
        activeFast = nil
        save()
        saveActive()
    }

    func cancelFast() {
        activeFast = nil
        saveActive()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Stats

    var completedEntries: [FastingEntry] { entries.filter { $0.isComplete } }

    var currentStreak: Int {
        guard !completedEntries.isEmpty else { return 0 }
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        for entry in completedEntries {
            let day = cal.startOfDay(for: entry.startTime)
            if day == checkDate || day == cal.date(byAdding: .day, value: -1, to: checkDate)! {
                streak += 1
                checkDate = day
            } else {
                break
            }
        }
        return streak
    }

    var longestFastHours: Double {
        completedEntries.compactMap { $0.duration }.max().map { $0 / 3600 } ?? 0
    }

    var averageFastHours: Double {
        let durs = completedEntries.compactMap { $0.duration }
        guard !durs.isEmpty else { return 0 }
        return durs.reduce(0, +) / Double(durs.count) / 3600
    }

    var goalMetCount: Int { completedEntries.filter { $0.goalMet }.count }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: saveURL)
        }
    }

    private func saveActive() {
        if let active = activeFast, let data = try? JSONEncoder().encode(active) {
            try? data.write(to: activeURL)
        } else {
            try? FileManager.default.removeItem(at: activeURL)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: saveURL),
           let decoded = try? JSONDecoder().decode([FastingEntry].self, from: data) {
            entries = decoded
        }
        if let data = try? Data(contentsOf: activeURL),
           let decoded = try? JSONDecoder().decode(FastingEntry.self, from: data) {
            activeFast = decoded
        }
    }
}
