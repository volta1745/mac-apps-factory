import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: DataStore
    @State private var filterLevel: Int = 0  // 0 = all

    private let levelLabels = ["All", "Exhausted", "Low", "Moderate", "High", "Peak"]
    private let levelEmojis = ["", "😴", "😔", "😐", "😊", "⚡️"]

    private var filtered: [DataStore.DayGroup] {
        guard filterLevel != 0 else { return store.entriesByDay }
        return store.entriesByDay.compactMap { group in
            let kept = group.entries.filter { $0.level == filterLevel }
            return kept.isEmpty ? nil : DataStore.DayGroup(id: group.id, entries: kept)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            Divider()
            if filtered.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.xmark",
                    title: "No entries found",
                    subtitle: filterLevel == 0
                        ? "Log some energy check-ins to see your history."
                        : "No \(levelLabels[filterLevel].lowercased()) energy entries yet."
                )
            } else {
                List {
                    ForEach(filtered) { group in
                        Section(header: sectionHeader(group.date, entries: group.entries)) {
                            ForEach(group.entries) { entry in
                                HistoryRow(entry: entry)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            }
                            .onDelete { offsets in
                                for i in offsets { store.delete(group.entries[i]) }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History (\(store.entries.count))")
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "All", isSelected: filterLevel == 0) { filterLevel = 0 }
                ForEach(1...5, id: \.self) { i in
                    FilterPill(
                        label: "\(levelEmojis[i]) \(levelLabels[i])",
                        isSelected: filterLevel == i
                    ) { filterLevel = i }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func sectionHeader(_ date: Date, entries: [EnergyEntry]) -> some View {
        let avg = Double(entries.map(\.level).reduce(0, +)) / Double(entries.count)
        let c = EnergyEntry.color(for: Int(avg.rounded()))
        return HStack {
            Text(date, style: .date)
                .font(.headline)
            Spacer()
            Text("avg \(String(format: "%.1f", avg))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color(red: c.r, green: c.g, blue: c.b))
            Text("• \(entries.count) log\(entries.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct HistoryRow: View {
    let entry: EnergyEntry

    private var c: (r: Double, g: Double, b: Double) { EnergyEntry.color(for: entry.level) }
    private var color: Color { Color(red: c.r, green: c.g, blue: c.b) }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                Text(entry.levelEmoji).font(.title3)
                Text("\(entry.level)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.levelLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(color)
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if !entry.factors.isEmpty {
                    Text(entry.factors.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.controlBackgroundColor))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
