import Foundation
import SwiftUI

// MARK: - Skill

struct Skill: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: SkillCategory
    var createdAt: Date = Date()

    static func == (lhs: Skill, rhs: Skill) -> Bool { lhs.id == rhs.id }
}

enum SkillCategory: String, CaseIterable, Codable, Identifiable {
    case music = "Music"
    case language = "Language"
    case art = "Art"
    case coding = "Coding"
    case sport = "Sport"
    case writing = "Writing"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .music:    return "music.note"
        case .language: return "text.bubble"
        case .art:      return "paintbrush"
        case .coding:   return "chevron.left.forwardslash.chevron.right"
        case .sport:    return "figure.run"
        case .writing:  return "pencil"
        case .other:    return "star"
        }
    }

    var color: Color {
        switch self {
        case .music:    return .purple
        case .language: return .blue
        case .art:      return .orange
        case .coding:   return .green
        case .sport:    return .red
        case .writing:  return .teal
        case .other:    return .gray
        }
    }
}

// MARK: - Practice Session

struct PracticeSession: Identifiable, Codable {
    var id: UUID = UUID()
    var skillId: UUID
    var date: Date = Date()
    var durationMinutes: Int
    var difficulty: Int          // 1 (easy) – 5 (very hard)
    var notes: String
}

// MARK: - Store

@MainActor
class SkillStore: ObservableObject {
    @Published var skills: [Skill] = []
    @Published var sessions: [PracticeSession] = []

    private let supportDir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("SkillLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var skillsURL: URL { supportDir.appendingPathComponent("skills.json") }
    private var sessionsURL: URL { supportDir.appendingPathComponent("sessions.json") }

    init() { load() }

    // MARK: Skill operations

    func addSkill(_ skill: Skill) {
        skills.append(skill)
        save()
    }

    func deleteSkill(_ skill: Skill) {
        skills.removeAll { $0.id == skill.id }
        sessions.removeAll { $0.skillId == skill.id }
        save()
    }

    // MARK: Session operations

    func addSession(_ session: PracticeSession) {
        sessions.append(session)
        save()
    }

    func deleteSession(_ session: PracticeSession) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    // MARK: Queries

    func sessions(for skill: Skill) -> [PracticeSession] {
        sessions.filter { $0.skillId == skill.id }
            .sorted { $0.date > $1.date }
    }

    func totalMinutes(for skill: Skill) -> Int {
        sessions(for: skill).reduce(0) { $0 + $1.durationMinutes }
    }

    func streak(for skill: Skill) -> Int {
        let dates = sessions(for: skill)
            .map { Calendar.current.startOfDay(for: $0.date) }
        let uniqueDays = Array(Set(dates)).sorted(by: >)
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var expected = Calendar.current.startOfDay(for: Date())
        for day in uniqueDays {
            if day == expected {
                streak += 1
                expected = Calendar.current.date(byAdding: .day, value: -1, to: expected)!
            } else if day < expected {
                break
            }
        }
        return streak
    }

    func recentActivity() -> [(Skill, PracticeSession)] {
        sessions
            .sorted { $0.date > $1.date }
            .prefix(20)
            .compactMap { session in
                guard let skill = skills.first(where: { $0.id == session.skillId }) else { return nil }
                return (skill, session)
            }
    }

    // MARK: Persistence

    private func load() {
        if let data = try? Data(contentsOf: skillsURL),
           let decoded = try? JSONDecoder().decode([Skill].self, from: data) {
            skills = decoded
        }
        if let data = try? Data(contentsOf: sessionsURL),
           let decoded = try? JSONDecoder().decode([PracticeSession].self, from: data) {
            sessions = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(skills) { try? data.write(to: skillsURL) }
        if let data = try? encoder.encode(sessions) { try? data.write(to: sessionsURL) }
    }
}
