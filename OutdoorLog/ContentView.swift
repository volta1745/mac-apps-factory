import SwiftUI

struct ContentView: View {
    @StateObject private var store = OutdoorStore()
    @State private var showingAdd = false
    @State private var filterActivity: ActivityType? = nil

    private let goalMinutes: Int = 30   // 30-min daily outdoor goal (WHO recommendation)

    private var filtered: [OutdoorEntry] {
        guard let f = filterActivity else { return store.entries }
        return store.entries.filter { $0.activity == f }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ───────────────────────────────────────────────────────
            headerBar

            Divider()

            // ── Stats row ────────────────────────────────────────────────────
            statsRow

            Divider()

            // ── Filter strip ─────────────────────────────────────────────────
            filterStrip

            Divider()

            // ── Entry list ───────────────────────────────────────────────────
            if filtered.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filtered) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { filtered[$0].id }
                        let storeOffsets = IndexSet(
                            ids.compactMap { id in store.entries.firstIndex(where: { $0.id == id }) }
                        )
                        store.delete(at: storeOffsets)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEntryView(store: store)
        }
    }

    // MARK: - Sub-views

    private var headerBar: some View {
        HStack {
            Image(systemName: "tree")
                .font(.title2)
                .foregroundColor(.green)
            Text("OutdoorLog")
                .font(.title2).bold()
            Spacer()
            Button {
                showingAdd = true
            } label: {
                Label("Log Outing", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            // Today's total
            statCard(
                label: "Today",
                value: formatDuration(store.todayMinutes),
                sub: "of \(formatDuration(goalMinutes)) goal",
                icon: "sun.max",
                color: .orange
            )
            Divider().frame(height: 50)

            // Goal progress ring
            goalRing

            Divider().frame(height: 50)

            // 7-day avg
            statCard(
                label: "7-Day Avg",
                value: formatDuration(store.weeklyAvgMinutes),
                sub: "per day",
                icon: "calendar",
                color: .blue
            )
            Divider().frame(height: 50)

            // Total entries
            statCard(
                label: "Total Outings",
                value: "\(store.entries.count)",
                sub: "all time",
                icon: "list.bullet",
                color: .purple
            )
        }
        .padding(.vertical, 12)
    }

    private var goalRing: some View {
        let progress = min(Double(store.todayMinutes) / Double(goalMinutes), 1.0)
        let met = store.todayMinutes >= goalMinutes
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(met ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if met {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.caption).bold()
                }
            }
            .frame(width: 52, height: 52)
            Text("Daily Goal")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func statCard(label: String, value: String, sub: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
            Text(value)
                .font(.title3).bold()
            Text(label)
                .font(.caption).foregroundColor(.secondary)
            Text(sub)
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", icon: "list.bullet", selected: filterActivity == nil) {
                    filterActivity = nil
                }
                ForEach(ActivityType.allCases, id: \.self) { type in
                    filterChip(label: type.rawValue, icon: nil, emoji: type.emoji, selected: filterActivity == type) {
                        filterActivity = (filterActivity == type) ? nil : type
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(label: String, icon: String?, emoji: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji).font(.caption)
                } else if let icon = icon {
                    Image(systemName: icon).font(.caption)
                }
                Text(label).font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tree")
                .font(.system(size: 48))
                .foregroundColor(.green.opacity(0.4))
            Text(filterActivity == nil ? "No outings logged yet" : "No \(filterActivity!.rawValue) entries")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Press ⌘N or click \"Log Outing\" to record time spent outdoors.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        if minutes == 0 { return "0 min" }
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: OutdoorEntry

    var body: some View {
        HStack(spacing: 12) {
            // Activity emoji
            Text(entry.activity.emoji)
                .font(.title2)
                .frame(width: 38, height: 38)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.activity.rawValue)
                        .font(.headline)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(entry.weather.emoji + " " + entry.weather.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Label(durationText(entry.durationMinutes), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    leafRating(entry.refreshmentRating)
                    Text(entry.refreshmentLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(entry.date, format: .dateTime.hour().minute())
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func durationText(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60; let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func leafRating(_ rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "leaf.fill" : "leaf")
                    .font(.system(size: 9))
                    .foregroundColor(i <= rating ? .green : .secondary.opacity(0.4))
            }
        }
    }
}
