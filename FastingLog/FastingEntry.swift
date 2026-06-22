import Foundation

enum FastingProtocol: String, CaseIterable, Codable {
    case sixteenEight  = "16:8"
    case eighteenSix   = "18:6"
    case twentyFour    = "20:4"
    case omad          = "OMAD"
    case custom        = "Custom"

    var goalHours: Double {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix:  return 18
        case .twentyFour:   return 20
        case .omad:         return 23
        case .custom:       return 16
        }
    }

    var description: String {
        switch self {
        case .sixteenEight: return "16 h fast / 8 h eating"
        case .eighteenSix:  return "18 h fast / 6 h eating"
        case .twentyFour:   return "20 h fast / 4 h eating"
        case .omad:         return "23 h fast / 1 h eating"
        case .custom:       return "Set your own goal"
        }
    }
}

struct FastingEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var startTime: Date
    var endTime: Date?
    var protocol_: FastingProtocol
    var goalHours: Double
    var notes: String

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var isComplete: Bool { endTime != nil }

    var goalMet: Bool {
        guard let dur = duration else { return false }
        return dur >= goalHours * 3600
    }

    private enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, protocol_, goalHours, notes
    }
}
