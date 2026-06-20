import Foundation

let allFactors: [String] = [
    "Good Sleep", "Exercise", "Healthy Meal", "Caffeine",
    "Fresh Air", "Hydrated", "Social", "Sunlight",
    "Poor Sleep", "Skipped Meal", "Stress", "Overworked",
    "Sick", "Junk Food"
]

let positiveFactors: Set<String> = [
    "Good Sleep", "Exercise", "Healthy Meal", "Caffeine",
    "Fresh Air", "Hydrated", "Social", "Sunlight"
]

struct EnergyEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var level: Int      // 1–5
    var factors: [String]
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), level: Int, factors: [String] = [], note: String = "") {
        self.id = id
        self.date = date
        self.level = level
        self.factors = factors
        self.note = note
    }

    var levelLabel: String {
        switch level {
        case 1: return "Exhausted"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Peak"
        default: return "—"
        }
    }

    var levelEmoji: String {
        switch level {
        case 1: return "😴"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "⚡️"
        default: return "❓"
        }
    }

    static func color(for level: Int) -> (r: Double, g: Double, b: Double) {
        switch level {
        case 1: return (0.85, 0.20, 0.20)   // red
        case 2: return (0.95, 0.50, 0.10)   // orange
        case 3: return (0.85, 0.75, 0.10)   // yellow
        case 4: return (0.20, 0.72, 0.35)   // green
        case 5: return (0.20, 0.50, 0.95)   // blue
        default: return (0.5, 0.5, 0.5)
        }
    }
}
