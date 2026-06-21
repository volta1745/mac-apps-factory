import SwiftUI

struct ContentView: View {
    @StateObject private var store = BreakStore()
    @State private var showingAdd = false
    @State private var filterType: BreakType? = nil

    var filteredGroups: [(key: String, entries: [BreakEntry])] {
        guard let f = filterType else { return store.groupedEntries }
        return store.groupedEntries.compactMap { group in
            let filtered = group.entries.filter { $0.breakType == f }
            return filtered.isEmpty ? nil : (key: group.key, entries: filtered)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top stats bar
            TodayStatsBar(store: store)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            HStack(spacing: 0) {
                // Filter sidebar
                FilterSidebar(selection: $filterType)
                    .frame(width: 150)
                    .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // History list
                if store.entries.isEmpty {
                    EmptyStateView(showingAdd: $showingAdd)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredGroups.isEmpty {
                    VStack {
                        Text("No \(filterType?.rawValue ?? "") breaks logged yet.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredGroups, id: \.key) { group in
                            Section(header: DayHeader(dateKey: group.key, entries: group.entries)) {
                                ForEach(group.entries) { entry in
                                    BreakRowView(entry: entry)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                store.delete(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Label("Log Break", systemImage: "plus.circle.fill")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddBreakView()
                .environmentObject(store)
        }
        .navigationTitle("BreakLog")
    }
}

// MARK: - Today Stats Bar

struct TodayStatsBar: View {
    @ObservedObject var store: BreakStore

    var body: some View {
        HStack(spacing: 0) {
            StatCell(
                value: "\(store.todayBreakCount)",
                label: "Breaks today",
                icon: "cup.and.saucer.fill",
                color: .blue
            )
            Divider().frame(height: 36).padding(.horizontal, 12)
            StatCell(
                value: "\(store.todayTotalMinutes) min",
                label: "Total break time",
                icon: "clock.fill",
                color: .green
            )
            Divider().frame(height: 36).padding(.horizontal, 12)
            StatCell(
                value: store.todayAvgRefreshment > 0
                    ? String(format: "%.1f / 5", store.todayAvgRefreshment)
                    : "—",
                label: "Avg refreshment",
                icon: "bolt.heart.fill",
                color: .orange
            )
            Spacer()
        }
    }
}

struct StatCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Filter Sidebar

struct FilterSidebar: View {
    @Binding var selection: BreakType?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Filter")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)

            FilterRow(label: "All Breaks", icon: "list.bullet", isSelected: selection == nil) {
                selection = nil
            }

            Divider().padding(.vertical, 4)

            ForEach(BreakType.allCases, id: \.self) { type in
                FilterRow(label: type.rawValue, icon: type.icon, isSelected: selection == type) {
                    selection = type
                }
            }
            Spacer()
        }
    }
}

struct FilterRow: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 18)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}

// MARK: - Day Header

struct DayHeader: View {
    let dateKey: String
    let entries: [BreakEntry]

    private var displayDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: dateKey) else { return dateKey }
        if Calendar.current.isDateInToday(d) { return "Today" }
        if Calendar.current.isDateInYesterday(d) { return "Yesterday" }
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }

    private var totalMin: Int { entries.reduce(0) { $0 + $1.durationMinutes } }

    var body: some View {
        HStack {
            Text(displayDate)
                .font(.subheadline.bold())
            Spacer()
            Text("\(entries.count) break\(entries.count == 1 ? "" : "s") · \(totalMin) min")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Break Row

struct BreakRowView: View {
    let entry: BreakEntry

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: entry.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: entry.breakType.icon)
                    .foregroundColor(typeColor)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.breakType.rawValue)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Label("\(entry.durationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= entry.refreshmentLevel ? "star.fill" : "star")
                                .foregroundColor(i <= entry.refreshmentLevel ? .yellow : .secondary.opacity(0.4))
                                .font(.system(size: 9))
                        }
                    }
                    if !entry.note.isEmpty {
                        Text("·")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text(entry.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var typeColor: Color {
        switch entry.breakType {
        case .micro: return .brown
        case .screenFree: return .purple
        case .walk: return .green
        case .stretch: return .blue
        case .lunch: return .orange
        case .powerNap: return .indigo
        case .fresh: return .teal
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    @Binding var showingAdd: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No breaks logged yet")
                .font(.title3.bold())
            Text("Take a break and log how refreshed it made you feel.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            Button("Log Your First Break") { showingAdd = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
