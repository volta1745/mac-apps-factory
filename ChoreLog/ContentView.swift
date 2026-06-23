import SwiftUI

struct ContentView: View {
    @StateObject private var store = ChoreStore()
    @State private var showingAdd = false
    @State private var selectedCategory: ChoreCategory? = nil
    @State private var searchText = ""

    var filteredEntries: [ChoreEntry] {
        store.entries.filter { entry in
            let matchesCategory = selectedCategory == nil || entry.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                entry.taskName.localizedCaseInsensitiveContains(searchText) ||
                entry.notes.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        HSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Stats panel
                VStack(spacing: 12) {
                    HStack {
                        Text("ChoreLog")
                            .font(.title2.bold())
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        StatTile(
                            value: "\(store.todayTaskCount)",
                            label: "Today",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        StatTile(
                            value: formatMinutes(store.todayTotalMinutes),
                            label: "Time today",
                            icon: "clock.fill",
                            color: .blue
                        )
                    }

                    let weekly = store.weeklyStats()
                    HStack(spacing: 12) {
                        StatTile(
                            value: "\(weekly.tasks)",
                            label: "This week",
                            icon: "calendar",
                            color: .orange
                        )
                        StatTile(
                            value: formatMinutes(weekly.minutes),
                            label: "Weekly time",
                            icon: "timer",
                            color: .purple
                        )
                    }
                }
                .padding(14)

                Divider()

                // Category filter
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filter by Category")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)

                    CategoryRow(
                        icon: "square.grid.2x2",
                        label: "All Chores",
                        isSelected: selectedCategory == nil
                    ) { selectedCategory = nil }

                    ForEach(ChoreCategory.allCases, id: \.self) { cat in
                        let count = store.entries.filter { $0.category == cat }.count
                        if count > 0 {
                            CategoryRow(
                                icon: cat.icon,
                                label: cat.rawValue,
                                count: count,
                                isSelected: selectedCategory == cat
                            ) { selectedCategory = cat }
                        }
                    }
                }
                .padding(.bottom, 8)

                Spacer()

                // Top chores
                if !store.categoryCounts().isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Top Categories")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        ForEach(store.categoryCounts().prefix(3), id: \.category) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 16)
                                Text(item.category.rawValue)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                }
            }
            .frame(width: 220)
            .background(Color(NSColor.windowBackgroundColor))

            // Main content
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    TextField("Search chores…", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)

                    Spacer()

                    Button {
                        showingAdd = true
                    } label: {
                        Label("Log Chore", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Divider()

                if filteredEntries.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "house.and.flag")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(store.entries.isEmpty ? "No chores logged yet" : "No results")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text(store.entries.isEmpty ? "Tap \"Log Chore\" to record a completed task." : "Try a different search or category.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                        if store.entries.isEmpty {
                            Button("Log First Chore") { showingAdd = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedByDay(filteredEntries), id: \.date) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    ChoreRowView(entry: entry)
                                }
                                .onDelete { offsets in
                                    let ids = offsets.map { group.entries[$0].id }
                                    store.entries.removeAll { ids.contains($0.id) }
                                }
                            } header: {
                                HStack {
                                    Text(group.label)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("\(group.entries.count) task\(group.entries.count == 1 ? "" : "s") · \(formatMinutes(group.entries.reduce(0) { $0 + $1.durationMinutes }))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddChoreView(store: store)
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ total: Int) -> String {
        if total < 60 { return "\(total)m" }
        let h = total / 60
        let m = total % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private struct DayGroup {
        let date: Date
        let label: String
        let entries: [ChoreEntry]
    }

    private func groupedByDay(_ entries: [ChoreEntry]) -> [DayGroup] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        var groups: [Date: [ChoreEntry]] = [:]
        for e in entries {
            let key = cal.startOfDay(for: e.completedAt)
            groups[key, default: []].append(e)
        }
        return groups.keys.sorted(by: >).map { date in
            var label: String
            if cal.isDateInToday(date) { label = "Today" }
            else if cal.isDateInYesterday(date) { label = "Yesterday" }
            else { label = fmt.string(from: date) }
            return DayGroup(date: date, label: label, entries: groups[date]!)
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

struct CategoryRow: View {
    let icon: String
    let label: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .frame(width: 16)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                Spacer()
                if let count {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }
}

struct ChoreRowView: View {
    let entry: ChoreEntry

    var effortColor: Color {
        switch entry.effortLevel {
        case 1: return .green
        case 2: return .mint
        case 3: return .orange
        case 4: return .red
        default: return .purple
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.category.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.taskName)
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    Label(entry.category.rawValue, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("\(entry.durationMinutes)m", systemImage: "clock")
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

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                            .foregroundColor(i <= entry.effortLevel ? effortColor : Color.secondary.opacity(0.2))
                    }
                }
                Text(entry.completedAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
