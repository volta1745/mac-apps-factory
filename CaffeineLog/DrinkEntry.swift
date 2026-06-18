import Foundation

struct DrinkEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date
    var drinkType: DrinkType
    var customName: String
    var caffeineMg: Int
    var notes: String

    var displayName: String {
        drinkType == .custom ? customName : drinkType.displayName
    }
}

enum DrinkType: String, Codable, CaseIterable {
    case espresso, coffee, americano, latte, cappuccino
    case blackTea, greenTea, matcha
    case energyDrink, cola, preworkout, custom

    var displayName: String {
        switch self {
        case .espresso:    return "Espresso"
        case .coffee:      return "Drip Coffee"
        case .americano:   return "Americano"
        case .latte:       return "Latte"
        case .cappuccino:  return "Cappuccino"
        case .blackTea:    return "Black Tea"
        case .greenTea:    return "Green Tea"
        case .matcha:      return "Matcha"
        case .energyDrink: return "Energy Drink"
        case .cola:        return "Cola"
        case .preworkout:  return "Pre-Workout"
        case .custom:      return "Custom"
        }
    }

    var defaultCaffeine: Int {
        switch self {
        case .espresso:    return 63
        case .coffee:      return 95
        case .americano:   return 120
        case .latte:       return 80
        case .cappuccino:  return 80
        case .blackTea:    return 47
        case .greenTea:    return 28
        case .matcha:      return 70
        case .energyDrink: return 160
        case .cola:        return 34
        case .preworkout:  return 200
        case .custom:      return 0
        }
    }

    var icon: String {
        switch self {
        case .espresso, .coffee, .americano, .latte, .cappuccino: return "cup.and.saucer.fill"
        case .blackTea, .greenTea, .matcha: return "leaf.fill"
        case .energyDrink, .preworkout: return "bolt.fill"
        case .cola: return "drop.fill"
        case .custom: return "questionmark.circle.fill"
        }
    }
}
