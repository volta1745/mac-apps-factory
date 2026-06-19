import Foundation

enum GratitudeCategory: String, Codable, CaseIterable, Identifiable {
    case family   = "Family"
    case friends  = "Friends"
    case work     = "Work"
    case health   = "Health"
    case nature   = "Nature"
    case learning = "Learning"
    case other    = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .family:   return "👨‍👩‍👧‍👦"
        case .friends:  return "🤝"
        case .work:     return "💼"
        case .health:   return "💪"
        case .nature:   return "🌿"
        case .learning: return "📚"
        case .other:    return "✨"
        }
    }

    var color: String {
        switch self {
        case .family:   return "orange"
        case .friends:  return "blue"
        case .work:     return "purple"
        case .health:   return "green"
        case .nature:   return "teal"
        case .learning: return "indigo"
        case .other:    return "gray"
        }
    }
}

struct GratitudeEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var category: GratitudeCategory
    var reflection: String
    var date: Date
}
