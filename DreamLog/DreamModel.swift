import Foundation
import SwiftUI

enum DreamType: String, CaseIterable, Codable {
    case normal = "Normal"
    case lucid = "Lucid"
    case recurring = "Recurring"
    case nightmare = "Nightmare"
    case vivid = "Vivid"
    case prophetic = "Prophetic"
    case abstract = "Abstract"

    var emoji: String {
        switch self {
        case .normal:    return "💭"
        case .lucid:     return "✨"
        case .recurring: return "🔄"
        case .nightmare: return "😱"
        case .vivid:     return "🌈"
        case .prophetic: return "🔮"
        case .abstract:  return "🌀"
        }
    }

    var color: Color {
        switch self {
        case .normal:    return .secondary
        case .lucid:     return .yellow
        case .recurring: return .orange
        case .nightmare: return .red
        case .vivid:     return .purple
        case .prophetic: return .mint
        case .abstract:  return .indigo
        }
    }
}

enum DreamEmotion: String, CaseIterable, Codable {
    case joyful      = "Joyful"
    case adventurous = "Adventurous"
    case romantic    = "Romantic"
    case mysterious  = "Mysterious"
    case neutral     = "Neutral"
    case anxious     = "Anxious"
    case sad         = "Sad"
    case scary       = "Scary"

    var emoji: String {
        switch self {
        case .joyful:      return "😄"
        case .adventurous: return "🚀"
        case .romantic:    return "💕"
        case .mysterious:  return "🤔"
        case .neutral:     return "😐"
        case .anxious:     return "😰"
        case .sad:         return "😢"
        case .scary:       return "😨"
        }
    }

    var color: Color {
        switch self {
        case .joyful:      return .yellow
        case .adventurous: return .blue
        case .romantic:    return .pink
        case .mysterious:  return .purple
        case .neutral:     return .gray
        case .anxious:     return .orange
        case .sad:         return .indigo
        case .scary:       return .red
        }
    }
}

struct DreamEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String
    var notes: String
    var dreamType: DreamType
    var emotion: DreamEmotion
    var clarity: Int       // 1–5: Fuzzy → Crystal Clear
    var sleepQuality: Int  // 1–5: Terrible → Excellent
}

// MARK: - Persistence

final class DreamStore: ObservableObject {
    @Published var entries: [DreamEntry] = []

    private let saveURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("DreamLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("dreams.json")
    }()

    init() { load() }

    func add(_ entry: DreamEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: saveURL)
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: saveURL),
           let decoded = try? JSONDecoder().decode([DreamEntry].self, from: data) {
            entries = decoded
        }
    }

    // MARK: Computed stats

    var totalEntries: Int { entries.count }

    var averageClarity: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.clarity).reduce(0, +)) / Double(entries.count)
    }

    var averageSleepQuality: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.sleepQuality).reduce(0, +)) / Double(entries.count)
    }

    var mostCommonType: DreamType? {
        let counts = Dictionary(grouping: entries, by: \.dreamType).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    var mostCommonEmotion: DreamEmotion? {
        let counts = Dictionary(grouping: entries, by: \.emotion).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    var typeCounts: [(DreamType, Int)] {
        DreamType.allCases.compactMap { type in
            let c = entries.filter { $0.dreamType == type }.count
            return c > 0 ? (type, c) : nil
        }.sorted { $0.1 > $1.1 }
    }

    var emotionCounts: [(DreamEmotion, Int)] {
        DreamEmotion.allCases.compactMap { e in
            let c = entries.filter { $0.emotion == e }.count
            return c > 0 ? (e, c) : nil
        }.sorted { $0.1 > $1.1 }
    }
}
