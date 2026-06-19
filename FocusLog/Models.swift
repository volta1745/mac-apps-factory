import Foundation

struct FocusSession: Codable, Identifiable {
    var id: UUID = UUID()
    var topic: String
    var startDate: Date
    var plannedMinutes: Int
    var actualMinutes: Int
    var notes: String
    var completed: Bool
}

class FocusStore: ObservableObject {
    @Published var sessions: [FocusSession] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FocusLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()

    init() { load() }

    func add(_ session: FocusSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([FocusSession].self, from: data)
        else { return }
        sessions = decoded
    }
}

enum TimerState {
    case idle, running, paused, finished
}

class FocusTimerManager: ObservableObject {
    @Published var state: TimerState = .idle
    @Published var secondsRemaining: Int = 25 * 60
    @Published var plannedMinutes: Int = 25 {
        didSet {
            if state == .idle { secondsRemaining = plannedMinutes * 60 }
        }
    }
    @Published var sessionStart: Date = Date()
    @Published var sessionCompleted: Bool = false

    private var timer: Timer?

    var timeString: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    var progress: Double {
        let total = plannedMinutes * 60
        return total > 0 ? Double(total - secondsRemaining) / Double(total) : 0
    }

    func start() {
        sessionStart = Date()
        secondsRemaining = plannedMinutes * 60
        sessionCompleted = false
        state = .running
        scheduleTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        state = .paused
    }

    func resume() {
        state = .running
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        sessionCompleted = false
        state = .finished
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        sessionCompleted = false
        secondsRemaining = plannedMinutes * 60
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.sessionCompleted = true
                self.state = .finished
            }
        }
    }
}
