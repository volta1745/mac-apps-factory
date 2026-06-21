import Foundation

struct Supplement: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var dosage: String
}

struct IntakeEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var supplementID: UUID
    var supplementName: String
    var supplementDosage: String
    var takenAt: Date

    var dateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: takenAt)
    }
}
