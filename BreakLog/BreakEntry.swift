import Foundation

enum BreakType: String, CaseIterable, Codable {
    case micro = "Micro-break"
    case screenFree = "Screen-free"
    case walk = "Walk"
    case stretch = "Stretch"
    case lunch = "Lunch"
    case powerNap = "Power nap"
    case fresh = "Fresh air"

    var icon: String {
        switch self {
        case .micro: return "cup.and.saucer"
        case .screenFree: return "eye.slash"
        case .walk: return "figure.walk"
        case .stretch: return "figure.flexibility"
        case .lunch: return "fork.knife"
        case .powerNap: return "moon.zzz"
        case .fresh: return "leaf"
        }
    }
}

struct BreakEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var breakType: BreakType
    var durationMinutes: Int       // 1–60
    var refreshmentLevel: Int      // 1–5
    var note: String

    var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
