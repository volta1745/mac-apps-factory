import Foundation

enum NapType: String, CaseIterable, Codable {
    case power = "Power Nap"
    case coffee = "Coffee Nap"
    case full = "Full Cycle"
    case micro = "Micro Nap"
    case yoga = "Yoga Nidra"

    var idealMinutes: Int {
        switch self {
        case .micro: return 5
        case .power: return 20
        case .coffee: return 25
        case .full: return 90
        case .yoga: return 30
        }
    }

    var icon: String {
        switch self {
        case .power: return "bolt.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .full: return "moon.zzz.fill"
        case .micro: return "timer"
        case .yoga: return "figure.mind.and.body"
        }
    }
}

struct NapEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var napType: NapType
    var durationMinutes: Int
    var sleepQuality: Int    // 1–5: how easily you fell asleep
    var alertnessAfter: Int  // 1–5: how alert you felt post-nap
    var notes: String

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var formattedTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

class NapStore: ObservableObject {
    @Published var entries: [NapEntry] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("NapLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: NapEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: NapEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([NapEntry].self, from: data) {
            entries = decoded
        }
    }

    var todayEntries: [NapEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var avgAlertness: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.alertnessAfter).reduce(0, +)) / Double(entries.count)
    }

    var avgDuration: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.durationMinutes).reduce(0, +)) / Double(entries.count)
    }

    var bestNapHour: String {
        guard !entries.isEmpty else { return "—" }
        let top = entries.max(by: { $0.alertnessAfter < $1.alertnessAfter })!
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: top.date)
    }
}
