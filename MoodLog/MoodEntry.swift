import Foundation

enum MoodLevel: Int, Codable, CaseIterable {
    case veryBad = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case great = 5

    var emoji: String {
        switch self {
        case .veryBad: return "😞"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .great: return "😄"
        }
    }

    var label: String {
        switch self {
        case .veryBad: return "Very Bad"
        case .bad: return "Bad"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .great: return "Great"
        }
    }

    var color: String {
        switch self {
        case .veryBad: return "red"
        case .bad: return "orange"
        case .neutral: return "yellow"
        case .good: return "green"
        case .great: return "teal"
        }
    }
}

struct MoodEntry: Identifiable, Codable {
    var id: UUID
    var date: Date
    var mood: MoodLevel
    var note: String

    init(mood: MoodLevel, note: String = "") {
        self.id = UUID()
        self.date = Date()
        self.mood = mood
        self.note = note
    }
}
