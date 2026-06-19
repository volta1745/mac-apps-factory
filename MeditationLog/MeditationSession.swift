import Foundation

enum MeditationType: String, CaseIterable, Codable {
    case breath = "Breathing"
    case bodyScan = "Body Scan"
    case visualization = "Visualization"
    case lovingKindness = "Loving-Kindness"
    case walking = "Walking"
    case sound = "Sound / Mantra"

    var symbol: String {
        switch self {
        case .breath: return "wind"
        case .bodyScan: return "figure.mind.and.body"
        case .visualization: return "eye.fill"
        case .lovingKindness: return "heart.fill"
        case .walking: return "figure.walk"
        case .sound: return "music.note"
        }
    }
}

struct MeditationSession: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var type: MeditationType
    var durationMinutes: Int          // 1–120
    var calmnessBefore: Int           // 1–5
    var calmnessAfter: Int            // 1–5
    var notes: String

    var calmnessDelta: Int { calmnessAfter - calmnessBefore }
}

// MARK: - Persistence

final class SessionStore: ObservableObject {
    @Published var sessions: [MeditationSession] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("MeditationLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()

    init() { load() }

    func add(_ session: MeditationSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    // MARK: Stats

    var totalMinutes: Int { sessions.reduce(0) { $0 + $1.durationMinutes } }
    var totalSessions: Int { sessions.count }

    var averageCalmnessDelta: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.calmnessDelta }) / Double(sessions.count)
    }

    var currentStreak: Int {
        guard !sessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let sortedDays = Set(sessions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        for day in sortedDays {
            if day == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    // MARK: Private

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([MeditationSession].self, from: data)
        else { return }
        sessions = decoded
    }
}
