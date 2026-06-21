import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: SupplementStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Intake History")
                    .font(.headline)
                Spacer()
                Text("\(store.entries.count) total logs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            if store.entriesByDate.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 46))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No history yet")
                        .foregroundColor(.secondary)
                    Text("Start logging supplements to see your history here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                Spacer()
            } else {
                List {
                    ForEach(store.entriesByDate, id: \.date) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.body)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.supplementName)
                                            .font(.body)
                                        Text(entry.supplementDosage)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(timeString(from: entry.takenAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        } header: {
                            HStack {
                                Text(formatDate(group.date))
                                    .font(.subheadline.bold())
                                Spacer()
                                let unique = Set(group.entries.map { $0.supplementID }).count
                                Text("\(unique) supplement\(unique == 1 ? "" : "s") taken")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    private func formatDate(_ key: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: key) else { return key }
        let out = DateFormatter()
        out.dateStyle = .long
        return out.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
