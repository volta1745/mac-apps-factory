import Foundation

struct SymptomEntry: Codable, Identifiable {
    var id: UUID
    var date: Date
    var symptom: String
    var severity: Int       // 1–5
    var bodyLocation: String
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        symptom: String,
        severity: Int,
        bodyLocation: String,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.symptom = symptom
        self.severity = severity
        self.bodyLocation = bodyLocation
        self.notes = notes
    }
}

// MARK: - Store

final class SymptomStore: ObservableObject {
    @Published private(set) var entries: [SymptomEntry] = []

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SymptomLog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("entries.json")
        load()
    }

    func add(_ entry: SymptomEntry) {
        entries.insert(entry, at: 0)
        persist()
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomicWrite)
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([SymptomEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
