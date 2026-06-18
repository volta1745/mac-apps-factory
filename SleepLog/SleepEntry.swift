import Foundation

struct SleepEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var bedtime: Date
    var wakeTime: Date
    var quality: Int   // 1–5
    var notes: String

    var durationMinutes: Int {
        let diff = wakeTime.timeIntervalSince(bedtime)
        return max(0, Int(diff / 60))
    }

    var durationText: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        switch (h, m) {
        case (0, _): return "\(m)m"
        case (_, 0): return "\(h)h"
        default:     return "\(h)h \(m)m"
        }
    }

    var qualityLabel: String {
        switch quality {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return ""
        }
    }
}
