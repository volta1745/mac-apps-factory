import SwiftUI

struct ContentView: View {
    @StateObject private var store = MoodStore()
    @State private var showingAddSheet = false
    @State private var selectedFilter: MoodLevel? = nil

    private var filteredEntries: [MoodEntry] {
        if let filter = selectedFilter {
            return store.entries.filter { $0.mood == filter }
        }
        return store.entries
    }

    private var moodCounts: [MoodLevel: Int] {
        Dictionary(grouping: store.entries, by: \.mood).mapValues(\.count)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMoodView(store: store)
        }
        .frame(minWidth: 720, minHeight: 500)
    }

    private var sidebar: some View {
        List(selection: $selectedFilter) {
            Section("Filter by Mood") {
                ForEach(MoodLevel.allCases, id: \.self) { level in
                    HStack {
                        Text(level.emoji)
                        Text(level.label)
                        Spacer()
                        Text("\(moodCounts[level] ?? 0)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .tag(Optional(level))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MoodLog")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    selectedFilter = nil
                } label: {
                    Label("Show All", systemImage: "line.3.horizontal.decrease.circle")
                }
                .help("Show all entries")
            }
        }
    }

    private var detail: some View {
        VStack(spacing: 0) {
            if filteredEntries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
        .navigationTitle(selectedFilter.map { "\($0.emoji) \($0.label)" } ?? "All Entries")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Log Mood", systemImage: "plus")
                }
                .help("Log a new mood entry")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🧘")
                .font(.system(size: 56))
            Text(selectedFilter == nil ? "No entries yet" : "No entries for this mood")
                .font(.title3)
                .foregroundColor(.secondary)
            if selectedFilter == nil {
                Button("Log Your First Mood") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryList: some View {
        List {
            ForEach(groupedByDay, id: \.date) { group in
                Section(header: Text(group.date)) {
                    ForEach(group.entries) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete { offsets in
                        deleteFromGroup(group: group, offsets: offsets)
                    }
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    private struct DayGroup {
        let date: String
        let entries: [MoodEntry]
    }

    private var groupedByDay: [DayGroup] {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        let grouped = Dictionary(grouping: filteredEntries) {
            formatter.string(from: $0.date)
        }
        return grouped
            .map { DayGroup(date: $0.key, entries: $0.value) }
            .sorted { lhs, rhs in
                let lhsDate = lhs.entries.first?.date ?? Date.distantPast
                let rhsDate = rhs.entries.first?.date ?? Date.distantPast
                return lhsDate > rhsDate
            }
    }

    private func deleteFromGroup(group: DayGroup, offsets: IndexSet) {
        let idsToDelete = offsets.map { group.entries[$0].id }
        let indices = store.entries.enumerated()
            .filter { idsToDelete.contains($0.element.id) }
            .map { $0.offset }
        store.delete(at: IndexSet(indices))
    }
}

struct EntryRow: View {
    let entry: MoodEntry

    private var timeString: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: entry.date)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(entry.mood.emoji)
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.mood.label)
                        .font(.headline)
                    Spacer()
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
