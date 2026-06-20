import SwiftUI

struct ContentView: View {
    @StateObject private var store = SocialStore()
    @State private var showingAdd = false
    @State private var filterType: InteractionType? = nil
    @State private var searchText: String = ""

    var filteredEntries: [SocialEntry] {
        store.entries.filter { entry in
            let typeMatch = filterType == nil || entry.interactionType == filterType
            let searchMatch = searchText.isEmpty
                || entry.personName.localizedCaseInsensitiveContains(searchText)
                || entry.notes.localizedCaseInsensitiveContains(searchText)
            return typeMatch && searchMatch
        }
    }

    var groupedEntries: [(String, [SocialEntry])] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        let dict = Dictionary(grouping: filteredEntries) { entry -> String in
            if cal.isDateInToday(entry.date) { return "Today" }
            if cal.isDateInYesterday(entry.date) { return "Yesterday" }
            return fmt.string(from: entry.date)
        }
        let sortedKeys = dict.keys.sorted { a, b in
            let aDate = dict[a]!.first!.date
            let bDate = dict[b]!.first!.date
            return aDate > bDate
        }
        return sortedKeys.map { ($0, dict[$0]!) }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Today's stats bar
                TodayStatsBar(store: store)
                    .padding()

                Divider()

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", icon: "list.bullet",
                                   selected: filterType == nil) {
                            filterType = nil
                        }
                        ForEach(InteractionType.allCases) { t in
                            FilterChip(label: t.rawValue, icon: t.icon,
                                       selected: filterType == t) {
                                filterType = (filterType == t) ? nil : t
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // Entry list
                if filteredEntries.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text(store.entries.isEmpty
                             ? "No interactions logged yet.\nTap + to add your first one."
                             : "No entries match your filter.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedEntries, id: \.0) { (day, dayEntries) in
                            Section(day) {
                                ForEach(dayEntries) { entry in
                                    EntryRow(entry: entry)
                                }
                                .onDelete { offsets in
                                    let ids = offsets.map { dayEntries[$0].id }
                                    store.entries.removeAll { ids.contains($0.id) }
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Social Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    .help("Log new interaction (⌘N)")
                }
            }
            .searchable(text: $searchText, prompt: "Search by name or notes")
            .sheet(isPresented: $showingAdd) {
                AddEntryView(store: store)
            }
        } detail: {
            Text("Select an entry or tap + to log a new interaction.")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Today Stats Bar

struct TodayStatsBar: View {
    @ObservedObject var store: SocialStore

    var body: some View {
        HStack(spacing: 20) {
            StatCell(value: "\(store.todayInteractions)",
                     label: "Today",
                     icon: "person.2.fill",
                     color: .blue)

            Divider().frame(height: 36)

            StatCell(value: store.todayMinutes >= 60
                        ? "\(store.todayMinutes / 60)h \(store.todayMinutes % 60)m"
                        : "\(store.todayMinutes)m",
                     label: "Time",
                     icon: "clock.fill",
                     color: .purple)

            Divider().frame(height: 36)

            if let avg = store.todayAverageEnergy {
                StatCell(value: String(format: "%.1f", avg),
                         label: "Avg Energy",
                         icon: "bolt.heart.fill",
                         color: energyColor(avg))
            } else {
                StatCell(value: "—",
                         label: "Avg Energy",
                         icon: "bolt.heart.fill",
                         color: .gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.07))
        .cornerRadius(10)
    }

    private func energyColor(_ avg: Double) -> Color {
        switch avg {
        case ..<2.0: return .red
        case ..<3.0: return .orange
        case ..<4.0: return .yellow
        case ..<4.5: return .green
        default: return .teal
        }
    }
}

struct StatCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(color).font(.caption)
                Text(value).font(.title3).fontWeight(.semibold)
            }
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: SocialEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Energy indicator dot
            Circle()
                .fill(energyColor(entry.energyImpact))
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.personName)
                        .font(.headline)
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 10) {
                    Label(entry.interactionType.rawValue, systemImage: entry.interactionType.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("·")
                        .foregroundColor(.secondary)

                    Label(entry.durationMinutes >= 60
                        ? "\(entry.durationMinutes / 60)h \(entry.durationMinutes % 60 > 0 ? "\(entry.durationMinutes % 60)m" : "")"
                        : "\(entry.durationMinutes) min",
                          systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("·")
                        .foregroundColor(.secondary)

                    Text(entry.energyLabel)
                        .font(.caption)
                        .foregroundColor(energyColor(entry.energyImpact))
                }

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func energyColor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .teal
        default: return .yellow
        }
    }
}
