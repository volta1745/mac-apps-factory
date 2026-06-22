import Foundation
import Combine

enum ScreenCategory: String, CaseIterable, Codable, Identifiable {
    case social = "Social Media"
    case work = "Work"
    case entertainment = "Entertainment"
    case gaming = "Gaming"
    case news = "News"
    case learning = "Learning"
    case shopping = "Shopping"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .social: return "person.2.fill"
        case .work: return "briefcase.fill"
        case .entertainment: return "play.rectangle.fill"
        case .gaming: return "gamecontroller.fill"
        case .news: return "newspaper.fill"
        case .learning: return "book.fill"
        case .shopping: return "cart.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: String {
        switch self {
        case .social: return "blue"
        case .work: return "indigo"
        case .entertainment: return "orange"
        case .gaming: return "purple"
        case .news: return "gray"
        case .learning: return "green"
        case .shopping: return "pink"
        case .other: return "secondary"
        }
    }
}

enum Purpose: String, CaseIterable, Codable, Identifiable {
    case mindful = "Mindful"
    case mindless = "Mindless"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mindful: return "checkmark.seal.fill"
        case .mindless: return "exclamationmark.triangle.fill"
        }
    }
}

struct ScreenSession: Identifiable, Codable {
    var id: UUID = UUID()
    var appName: String
    var category: ScreenCategory
    var durationMinutes: Int
    var purpose: Purpose
    var note: String
    var date: Date = Date()
}

class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published var sessions: [ScreenSession] = []
    @Published var dailyLimitMinutes: Int = 120

    private let dataURL: URL
    private let limitKey = "screenlog_daily_limit"

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("ScreenLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        dataURL = dir.appendingPathComponent("sessions.json")
        dailyLimitMinutes = UserDefaults.standard.integer(forKey: limitKey) == 0
            ? 120
            : UserDefaults.standard.integer(forKey: limitKey)
        load()
    }

    func add(_ session: ScreenSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    func saveLimit(_ minutes: Int) {
        dailyLimitMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: limitKey)
    }

    // MARK: Today helpers

    var todaySessions: [ScreenSession] {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.date) }
    }

    var todayTotalMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var todayMindfulMinutes: Int {
        todaySessions.filter { $0.purpose == .mindful }.reduce(0) { $0 + $1.durationMinutes }
    }

    var todayMindlessMinutes: Int {
        todaySessions.filter { $0.purpose == .mindless }.reduce(0) { $0 + $1.durationMinutes }
    }

    func todayMinutes(for category: ScreenCategory) -> Int {
        todaySessions.filter { $0.category == category }.reduce(0) { $0 + $1.durationMinutes }
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: dataURL),
              let decoded = try? JSONDecoder().decode([ScreenSession].self, from: data) else { return }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: dataURL, options: .atomic)
    }
}
