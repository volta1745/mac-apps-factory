import Foundation

struct ReadingSession: Identifiable, Codable {
    var id: UUID = UUID()
    var bookTitle: String
    var author: String
    var startPage: Int
    var endPage: Int
    var durationMinutes: Int
    var notes: String
    var date: Date

    var pagesRead: Int { max(0, endPage - startPage) }
}

class ReadingStore: ObservableObject {
    @Published var sessions: [ReadingSession] = []

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("ReadLog")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()

    init() { load() }

    func add(_ session: ReadingSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    var sessionsThisWeek: Int {
        sessions.filter { $0.date >= weekAgo }.count
    }

    var totalPagesThisWeek: Int {
        sessions.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.pagesRead }
    }

    var totalMinutesThisWeek: Int {
        sessions.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.durationMinutes }
    }

    private var weekAgo: Date {
        Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ReadingSession].self, from: data) else { return }
        sessions = decoded
    }
}
