import Foundation

enum InteractionType: String, Codable, CaseIterable, Identifiable {
    case inPerson = "In Person"
    case phone = "Phone Call"
    case videoCall = "Video Call"
    case message = "Text / Message"
    case groupEvent = "Group Event"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .inPerson:   return "person.2.fill"
        case .phone:      return "phone.fill"
        case .videoCall:  return "video.fill"
        case .message:    return "message.fill"
        case .groupEvent: return "person.3.fill"
        }
    }
}

struct SocialEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var personName: String
    var interactionType: InteractionType
    var durationMinutes: Int
    var energyImpact: Int     // 1 = very drained … 5 = very energized
    var notes: String

    var energyLabel: String {
        switch energyImpact {
        case 1: return "Very Drained"
        case 2: return "Slightly Drained"
        case 3: return "Neutral"
        case 4: return "Energized"
        case 5: return "Very Energized"
        default: return "Neutral"
        }
    }

    var energyColor: String {
        switch energyImpact {
        case 1: return "red"
        case 2: return "orange"
        case 3: return "yellow"
        case 4: return "green"
        case 5: return "teal"
        default: return "yellow"
        }
    }
}

class SocialStore: ObservableObject {
    @Published var entries: [SocialEntry] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("SocialLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: SocialEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    var todayEntries: [SocialEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.date) }
    }

    var todayInteractions: Int { todayEntries.count }

    var todayMinutes: Int { todayEntries.reduce(0) { $0 + $1.durationMinutes } }

    var todayAverageEnergy: Double? {
        guard !todayEntries.isEmpty else { return nil }
        let sum = todayEntries.reduce(0.0) { $0 + Double($1.energyImpact) }
        return sum / Double(todayEntries.count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SocialEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
