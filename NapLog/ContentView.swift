import SwiftUI

struct ContentView: View {
    @StateObject private var store = NapStore()
    @State private var showAdd = false
    @State private var filterType: NapType? = nil
    @State private var searchText = ""

    var filtered: [NapEntry] {
        store.entries.filter { entry in
            (filterType == nil || entry.napType == filterType) &&
            (searchText.isEmpty ||
             entry.napType.rawValue.localizedCaseInsensitiveContains(searchText) ||
             entry.notes.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "bed.double.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)
                        Text("NapLog")
                            .font(.title2).bold()
                    }
                    Text("Track your rest sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { showAdd = true }) {
                    Label("Log Nap", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Stats bar
            StatsBarView(store: store)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            Divider()

            // Filter chips + search
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: filterType == nil) {
                    filterType = nil
                }
                ForEach(NapType.allCases, id: \.self) { type in
                    FilterChip(label: type.rawValue, isSelected: filterType == type) {
                        filterType = filterType == type ? nil : type
                    }
                }
                Spacer()
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 120)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider()

            // Entry list
            if filtered.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(groupedEntries, id: \.0) { day, dayEntries in
                        Section(header: Text(day).font(.caption).foregroundColor(.secondary)) {
                            ForEach(dayEntries) { entry in
                                NapRowView(entry: entry)
                                    .swipeActions(edge: .trailing) {
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
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddNapView(store: store)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    var groupedEntries: [(String, [NapEntry])] {
        let grouped = Dictionary(grouping: filtered) { $0.dayKey }
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
    }
}

struct StatsBarView: View {
    @ObservedObject var store: NapStore

    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(store.todayEntries.count)", label: "Today", icon: "sun.max", color: .orange)
            Divider().frame(height: 36)
            StatCell(
                value: store.entries.isEmpty ? "—" : String(format: "%.0f min", store.avgDuration),
                label: "Avg Duration",
                icon: "timer",
                color: .teal
            )
            Divider().frame(height: 36)
            StatCell(
                value: store.entries.isEmpty ? "—" : String(format: "%.1f★", store.avgAlertness),
                label: "Avg Alertness",
                icon: "sun.max.fill",
                color: .yellow
            )
            Divider().frame(height: 36)
            StatCell(value: store.bestNapHour, label: "Best Nap Time", icon: "clock.badge.checkmark", color: .indigo)
        }
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.18)))
    }
}

struct StatCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).foregroundColor(color).font(.caption)
            Text(value).font(.system(.subheadline, design: .rounded)).bold()
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.indigo : Color(nsColor: .controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.clear : Color.secondary.opacity(0.25)))
        }
        .buttonStyle(.plain)
    }
}

struct NapRowView: View {
    let entry: NapEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: entry.napType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.indigo)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.napType.rawValue)
                        .font(.subheadline).bold()
                    Spacer()
                    Text(entry.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 10) {
                    Label("\(entry.durationMinutes) min", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    qualityDots(label: "Sleep", value: entry.sleepQuality, color: .indigo)
                    qualityDots(label: "Alert", value: entry.alertnessAfter, color: .orange)
                }
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    func qualityDots(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.secondary)
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= value ? color : Color.secondary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bed.double")
                .font(.system(size: 52))
                .foregroundColor(.indigo.opacity(0.35))
            Text("No naps logged yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Tap \"Log Nap\" to record your first rest session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
