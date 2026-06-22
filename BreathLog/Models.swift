import Foundation

enum BreathTechnique: String, CaseIterable, Codable {
    case boxBreathing     = "Box Breathing"
    case breathing478     = "4-7-8"
    case wimHof           = "Wim Hof"
    case diaphragmatic    = "Diaphragmatic"
    case alternateNostril = "Alternate Nostril"
    case coherence        = "Coherence"
    case custom           = "Custom"

    var icon: String {
        switch self {
        case .boxBreathing:     return "square"
        case .breathing478:     return "timer"
        case .wimHof:           return "flame"
        case .diaphragmatic:    return "lungs"
        case .alternateNostril: return "arrow.left.arrow.right"
        case .coherence:        return "waveform.path"
        case .custom:           return "star"
        }
    }

    var hint: String {
        switch self {
        case .boxBreathing:     return "4 s in · 4 s hold · 4 s out · 4 s hold"
        case .breathing478:     return "4 s in · 7 s hold · 8 s out"
        case .wimHof:           return "30–40 power breaths + breath retention"
        case .diaphragmatic:    return "Slow, deep belly breathing"
        case .alternateNostril: return "Nadi Shodhana pranayama"
        case .coherence:        return "5.5 s in · 5.5 s out (resonance breathing)"
        case .custom:           return "Your own technique"
        }
    }
}

struct BreathSession: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var technique: BreathTechnique
    var rounds: Int
    var durationMinutes: Int
    var stressBefore: Int   // 1–5
    var calmAfter: Int      // 1–5
    var notes: String
}

class BreathStore: ObservableObject {
    @Published var sessions: [BreathSession] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("BreathLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()

    init() { load() }

    func add(_ session: BreathSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(ids: Set<UUID>) {
        sessions.removeAll { ids.contains($0.id) }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([BreathSession].self, from: data) else { return }
        sessions = decoded
    }

    // MARK: – Stats

    var todaySessions: [BreathSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayTotalMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var allTimeAvgCalm: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.calmAfter }) / Double(sessions.count)
    }

    var avgStressReduction: Double {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + ($1.calmAfter - $1.stressBefore) }
        return Double(total) / Double(sessions.count)
    }
}
