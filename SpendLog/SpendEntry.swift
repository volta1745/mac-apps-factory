import Foundation

struct SpendEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var amount: Double
    var category: Category
    var note: String

    enum Category: String, CaseIterable, Codable, Identifiable {
        case food         = "Food"
        case transport    = "Transport"
        case shopping     = "Shopping"
        case entertainment = "Entertainment"
        case health       = "Health"
        case utilities    = "Utilities"
        case other        = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .food:          return "fork.knife"
            case .transport:     return "car.fill"
            case .shopping:      return "bag.fill"
            case .entertainment: return "film.fill"
            case .health:        return "cross.fill"
            case .utilities:     return "bolt.fill"
            case .other:         return "ellipsis.circle.fill"
            }
        }
    }
}
