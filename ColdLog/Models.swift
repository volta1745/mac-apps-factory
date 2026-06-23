import Foundation

enum ExposureType: String, CaseIterable, Codable {
    case coldShower = "Cold Shower"
    case iceBath = "Ice Bath"
    case coldPlunge = "Cold Plunge"
    case outdoorSwim = "Outdoor Swim"
    case snowRoll = "Snow / Winter Exposure"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .coldShower: return "🚿"
        case .iceBath: return "🧊"
        case .coldPlunge: return "🪣"
        case .outdoorSwim: return "🏊"
        case .snowRoll: return "❄️"
        case .custom: return "🌡️"
        }
    }
}

struct ColdSession: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var type: ExposureType
    var durationSeconds: Int
    var temperatureCelsius: Double?
    var moodBefore: Int
    var moodAfter: Int
    var notes: String

    var durationFormatted: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m)m" }
        return "\(m)m \(s)s"
    }

    var temperatureFormatted: String {
        guard let t = temperatureCelsius else { return "—" }
        return String(format: "%.0f°C", t)
    }

    var moodDelta: Int { moodAfter - moodBefore }
}

final class ColdStore: ObservableObject {
    @Published var sessions: [ColdSession] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("ColdLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()

    init() { load() }

    func add(_ session: ColdSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Computed stats

    var todaySessions: [ColdSession] {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.date) }
    }

    var streak: Int {
        guard !sessions.isEmpty else { return 0 }
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        var count = 0
        var idx = 0
        while idx < sessions.count {
            let sessionDay = cal.startOfDay(for: sessions[idx].date)
            if sessionDay == day {
                count += 1
                idx += 1
            } else if sessionDay < day {
                day = cal.date(byAdding: .day, value: -1, to: day)!
                if sessionDay != day { break }
            } else {
                idx += 1
            }
        }
        return count
    }

    var longestDuration: Int {
        sessions.map(\.durationSeconds).max() ?? 0
    }

    var averageMoodLift: Double {
        let lifted = sessions.filter { $0.moodDelta > 0 }
        guard !lifted.isEmpty else { return 0 }
        return Double(lifted.map(\.moodDelta).reduce(0, +)) / Double(lifted.count)
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ColdSession].self, from: data)
        else { return }
        sessions = decoded
    }
}
