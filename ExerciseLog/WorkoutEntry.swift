import SwiftUI

struct WorkoutEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var workoutType: WorkoutType
    var durationMinutes: Int
    var intensity: Intensity
    var notes: String

    enum WorkoutType: String, Codable, CaseIterable {
        case running   = "Running"
        case cycling   = "Cycling"
        case strength  = "Strength"
        case hiit      = "HIIT"
        case swimming  = "Swimming"
        case yoga      = "Yoga"
        case walking   = "Walking"
        case other     = "Other"

        var emoji: String {
            switch self {
            case .running:  return "🏃"
            case .cycling:  return "🚴"
            case .strength: return "💪"
            case .hiit:     return "⚡️"
            case .swimming: return "🏊"
            case .yoga:     return "🧘"
            case .walking:  return "🚶"
            case .other:    return "🏋️"
            }
        }
    }

    enum Intensity: String, Codable, CaseIterable {
        case easy     = "Easy"
        case moderate = "Moderate"
        case hard     = "Hard"

        var color: Color {
            switch self {
            case .easy:     return .green
            case .moderate: return .orange
            case .hard:     return .red
            }
        }
    }
}
