import Foundation

enum ActivityType: String, CaseIterable, Codable {
    case walk       = "Walk"
    case run        = "Run"
    case cycling    = "Cycling"
    case gardening  = "Gardening"
    case sitting    = "Sitting Outside"
    case sports     = "Sports"
    case commute    = "Commute"
    case errand     = "Errand"
    case hiking     = "Hiking"
    case other      = "Other"

    var emoji: String {
        switch self {
        case .walk:      return "🚶"
        case .run:       return "🏃"
        case .cycling:   return "🚴"
        case .gardening: return "🌱"
        case .sitting:   return "🪑"
        case .sports:    return "⚽"
        case .commute:   return "🚇"
        case .errand:    return "🛍️"
        case .hiking:    return "🥾"
        case .other:     return "🌿"
        }
    }
}

enum WeatherType: String, CaseIterable, Codable {
    case sunny      = "Sunny"
    case partlyCloudy = "Partly Cloudy"
    case cloudy     = "Cloudy"
    case windy      = "Windy"
    case rainy      = "Rainy"
    case foggy      = "Foggy"
    case snowy      = "Snowy"

    var emoji: String {
        switch self {
        case .sunny:        return "☀️"
        case .partlyCloudy: return "⛅"
        case .cloudy:       return "☁️"
        case .windy:        return "🌬️"
        case .rainy:        return "🌧️"
        case .foggy:        return "🌫️"
        case .snowy:        return "❄️"
        }
    }
}

struct OutdoorEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var durationMinutes: Int
    var activity: ActivityType
    var weather: WeatherType
    var refreshmentRating: Int   // 1–5
    var notes: String

    var refreshmentLabel: String {
        switch refreshmentRating {
        case 1: return "Draining"
        case 2: return "Neutral"
        case 3: return "Okay"
        case 4: return "Refreshing"
        case 5: return "Energizing"
        default: return ""
        }
    }
}
