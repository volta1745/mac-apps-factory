import Foundation
import SwiftUI

enum PostureRating: String, CaseIterable, Codable {
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var emoji: String {
        switch self {
        case .good: return "✅"
        case .fair: return "⚠️"
        case .poor: return "❌"
        }
    }

    var score: Int {
        switch self {
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }

    var color: Color {
        switch self {
        case .good: return .green
        case .fair: return .orange
        case .poor: return .red
        }
    }

    var systemImage: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .poor: return "xmark.circle.fill"
        }
    }
}

enum BodyArea: String, CaseIterable, Codable {
    case neck = "Neck"
    case shoulders = "Shoulders"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"
    case hips = "Hips"
    case wrists = "Wrists"
}

enum CorrectiveAction: String, CaseIterable, Codable {
    case none = "None taken"
    case stoodUp = "Stood up"
    case stretched = "Stretched"
    case adjustedChair = "Adjusted chair"
    case adjustedMonitor = "Adjusted monitor"
    case walkedAround = "Walked around"
    case appliedHeat = "Applied heat/ice"
}

struct PostureEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var rating: PostureRating
    var affectedAreas: [BodyArea]
    var discomfortLevel: Int   // 0 = none … 5 = severe
    var correctiveAction: CorrectiveAction
    var notes: String
}

class PostureStore: ObservableObject {
    @Published var entries: [PostureEntry] = []

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PostureLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("entries.json")
    }()

    init() { load() }

    func add(_ entry: PostureEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    var todayEntries: [PostureEntry] {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    var todayAverageScore: Double {
        let t = todayEntries
        guard !t.isEmpty else { return 0 }
        return Double(t.map(\.rating.score).reduce(0, +)) / Double(t.count)
    }

    var todayGoodCount: Int { todayEntries.filter { $0.rating == .good }.count }
    var todayFairCount: Int { todayEntries.filter { $0.rating == .fair }.count }
    var todayPoorCount: Int { todayEntries.filter { $0.rating == .poor }.count }

    var todayMostAffectedArea: BodyArea? {
        let areas = todayEntries.flatMap(\.affectedAreas)
        guard !areas.isEmpty else { return nil }
        return BodyArea.allCases.max { a, b in
            areas.filter { $0 == a }.count < areas.filter { $0 == b }.count
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: saveURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([PostureEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
