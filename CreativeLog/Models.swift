import Foundation

enum CreativeType: String, CaseIterable, Codable, Identifiable {
    case writing    = "Writing"
    case music      = "Music"
    case drawing    = "Drawing"
    case photography = "Photography"
    case design     = "Design"
    case coding     = "Coding"
    case crafts     = "Crafts"
    case other      = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .writing:     return "✍️"
        case .music:       return "🎵"
        case .drawing:     return "🎨"
        case .photography: return "📷"
        case .design:      return "💡"
        case .coding:      return "💻"
        case .crafts:      return "🧶"
        case .other:       return "⭐"
        }
    }

    var color: String {
        switch self {
        case .writing:     return "indigo"
        case .music:       return "purple"
        case .drawing:     return "orange"
        case .photography: return "cyan"
        case .design:      return "pink"
        case .coding:      return "green"
        case .crafts:      return "brown"
        case .other:       return "gray"
        }
    }
}

struct CreativeSession: Identifiable, Codable {
    var id: UUID
    var date: Date
    var type: CreativeType
    var project: String
    var durationMinutes: Int
    var flowLevel: Int   // 1–5
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: CreativeType,
        project: String,
        durationMinutes: Int,
        flowLevel: Int,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.project = project
        self.durationMinutes = durationMinutes
        self.flowLevel = flowLevel
        self.notes = notes
    }

    var flowLabel: String {
        switch flowLevel {
        case 1: return "Blocked"
        case 2: return "Sluggish"
        case 3: return "Steady"
        case 4: return "Flowing"
        case 5: return "In the Zone"
        default: return "—"
        }
    }

    var durationFormatted: String {
        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        }
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

import Combine

class SessionStore: ObservableObject {
    @Published var sessions: [CreativeSession] = []

    private let saveURL: URL = {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CreativeLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()

    init() { load() }

    func add(_ session: CreativeSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Derived stats

    var totalMinutes: Int { sessions.reduce(0) { $0 + $1.durationMinutes } }

    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        while true {
            let hasSession = sessions.contains { cal.isDate($0.date, inSameDayAs: checkDate) }
            if hasSession {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else if streak == 0 {
                // Allow today to have no entry yet
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
                let yday = sessions.contains { cal.isDate($0.date, inSameDayAs: checkDate) }
                if yday { streak += 1; checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!; continue }
                break
            } else {
                break
            }
        }
        return streak
    }

    func minutesByType() -> [(CreativeType, Int)] {
        var map: [CreativeType: Int] = [:]
        for s in sessions { map[s.type, default: 0] += s.durationMinutes }
        return map.sorted { $0.value > $1.value }
    }

    func sessionsLast7Days() -> [(Date, Int)] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset -> (Date, Int) in
            let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let mins = sessions
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationMinutes }
            return (day, mins)
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: saveURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([CreativeSession].self, from: data)
        else { return }
        sessions = decoded
    }
}
