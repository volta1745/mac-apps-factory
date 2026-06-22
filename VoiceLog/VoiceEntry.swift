import Foundation
import SwiftUI

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case singing      = "Singing"
    case speaking     = "Public Speaking"
    case teaching     = "Teaching"
    case podcast      = "Podcast/Recording"
    case performance  = "Performance"
    case rehearsal    = "Rehearsal"
    case conversation = "Long Conversation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .singing:      return "mic.fill"
        case .speaking:     return "person.wave.2.fill"
        case .teaching:     return "graduationcap.fill"
        case .podcast:      return "waveform.badge.mic"
        case .performance:  return "star.fill"
        case .rehearsal:    return "arrow.counterclockwise"
        case .conversation: return "bubble.left.and.bubble.right.fill"
        }
    }

    var color: Color {
        switch self {
        case .singing:      return .purple
        case .speaking:     return .blue
        case .teaching:     return .orange
        case .podcast:      return .red
        case .performance:  return .yellow
        case .rehearsal:    return .green
        case .conversation: return .teal
        }
    }
}

struct VoiceEntry: Codable, Identifiable {
    var id: UUID
    var date: Date
    var sessionType: SessionType
    var durationMinutes: Int
    var strainLevel: Int    // 1 (none) – 5 (very strained)
    var warmUpDone: Bool
    var hydrated: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        sessionType: SessionType = .singing,
        durationMinutes: Int = 30,
        strainLevel: Int = 2,
        warmUpDone: Bool = false,
        hydrated: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.sessionType = sessionType
        self.durationMinutes = durationMinutes
        self.strainLevel = strainLevel
        self.warmUpDone = warmUpDone
        self.hydrated = hydrated
        self.notes = notes
    }
}

class VoiceStore: ObservableObject {
    @Published var entries: [VoiceEntry] = []

    private let saveURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("VoiceLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: VoiceEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(ids: Set<UUID>) {
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Today stats

    var todayEntries: [VoiceEntry] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayTotalMinutes: Int {
        todayEntries.reduce(0) { $0 + $1.durationMinutes }
    }

    var todayAvgStrain: Double {
        guard !todayEntries.isEmpty else { return 0 }
        return Double(todayEntries.reduce(0) { $0 + $1.strainLevel }) / Double(todayEntries.count)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: saveURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([VoiceEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
