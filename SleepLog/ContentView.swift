import SwiftUI

struct ContentView: View {
    @StateObject private var store = SleepStore()
    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 0) {
            summaryBar
            Divider()
            entryList
        }
        .frame(minWidth: 520, minHeight: 420)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAdd = true
                } label: {
                    Label("Log Sleep", systemImage: "plus")
                }
                .help("Log a new sleep session")
            }
        }
        .navigationTitle("Sleep Log")
        .sheet(isPresented: $showingAdd) {
            AddSleepEntryView { entry in
                store.add(entry)
            }
        }
    }

    // MARK: - Subviews

    private var summaryBar: some View {
        HStack(spacing: 0) {
            SummaryTile(
                icon: "moon.fill",
                iconColor: .indigo,
                label: "Avg Duration (7d)",
                value: store.avgHoursLast7.map { String(format: "%.1f h", $0) } ?? "—"
            )
            Divider().frame(height: 48)
            SummaryTile(
                icon: "star.fill",
                iconColor: .yellow,
                label: "Avg Quality (7d)",
                value: store.avgQualityLast7.map { String(format: "%.1f / 5", $0) } ?? "—"
            )
            Divider().frame(height: 48)
            SummaryTile(
                icon: "calendar",
                iconColor: .blue,
                label: "Total Entries",
                value: "\(store.entries.count)"
            )
        }
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var entryList: some View {
        Group {
            if store.entries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.entries) { entry in
                        SleepEntryRow(entry: entry)
                    }
                    .onDelete(perform: store.delete)
                }
                .listStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 52))
                .foregroundColor(.indigo.opacity(0.5))
            Text("No sleep entries yet")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Click + to log your first night's sleep.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - SummaryTile

struct SummaryTile: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(value)
                    .font(.title3.bold())
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SleepEntryRow

struct SleepEntryRow: View {
    let entry: SleepEntry

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Moon icon with quality color
            Image(systemName: "moon.fill")
                .font(.title2)
                .foregroundColor(qualityColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text("Woke up \(Self.dateFormatter.string(from: entry.wakeTime))")
                    .font(.headline)
                Text("Bedtime: \(Self.dateFormatter.string(from: entry.bedtime))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.durationText)
                    .font(.title3.bold())
                    .foregroundColor(.indigo)
                starsView
                Text(entry.qualityLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var starsView: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= entry.quality ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
    }

    private var qualityColor: Color {
        switch entry.quality {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }
}
