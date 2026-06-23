import SwiftUI

struct ContentView: View {
    @StateObject private var store = ColdStore()
    @State private var showingAdd = false
    @State private var filterType: ExposureType? = nil
    @State private var searchText = ""

    var filtered: [ColdSession] {
        var list = store.sessions
        if let f = filterType { list = list.filter { $0.type == f } }
        if !searchText.isEmpty {
            list = list.filter {
                $0.type.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPanel
        }
        .sheet(isPresented: $showingAdd) {
            AddSessionView(store: store)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            statsHeader
            Divider()
            filterBar
            Divider()
            sessionList
        }
        .navigationTitle("ColdLog")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
                .help("Log a cold session")
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search sessions")
    }

    // MARK: - Stats header

    private var statsHeader: some View {
        HStack(spacing: 0) {
            statCell(value: "\(store.sessions.count)", label: "Total")
            Divider().frame(height: 36)
            statCell(value: "\(store.streak)", label: "Day Streak")
            Divider().frame(height: 36)
            statCell(value: "\(store.todaySessions.count)", label: "Today")
            Divider().frame(height: 36)
            statCell(value: store.longestDuration > 0 ? ColdSession(
                type: .coldShower, durationSeconds: store.longestDuration,
                moodBefore: 3, moodAfter: 3, notes: "").durationFormatted : "—",
                     label: "Longest")
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(label: "All", icon: "❄️", selected: filterType == nil) {
                    filterType = nil
                }
                ForEach(ExposureType.allCases, id: \.self) { t in
                    FilterChip(label: t.rawValue, icon: t.icon, selected: filterType == t) {
                        filterType = filterType == t ? nil : t
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Session list

    private var sessionList: some View {
        Group {
            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Text("❄️")
                        .font(.system(size: 44))
                    Text(store.sessions.isEmpty ? "No sessions yet" : "No matches")
                        .foregroundStyle(.secondary)
                    if store.sessions.isEmpty {
                        Button("Log your first session") { showingAdd = true }
                            .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedByDay(filtered), id: \.0) { day, items in
                        Section(header: Text(day).font(.caption).foregroundStyle(.secondary)) {
                            ForEach(items) { session in
                                SessionRow(session: session)
                            }
                            .onDelete { offsets in
                                let ids = Set(offsets.map { items[$0].id })
                                let globalOffsets = IndexSet(
                                    store.sessions.indices.filter { ids.contains(store.sessions[$0].id) }
                                )
                                store.delete(at: globalOffsets)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    // MARK: - Detail panel

    private var detailPanel: some View {
        VStack(spacing: 20) {
            Image(systemName: "thermometer.snowflake")
                .font(.system(size: 52))
                .foregroundStyle(.blue.opacity(0.7))
            Text("ColdLog")
                .font(.title.bold())
            Text("Track cold showers, ice baths,\nand cold plunges to build resilience.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if store.averageMoodLift > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                    Text(String(format: "Average mood lift: +%.1f pts", store.averageMoodLift))
                        .foregroundStyle(.secondary)
                }
            }

            Button("Log Session") { showingAdd = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func groupedByDay(_ items: [ColdSession]) -> [(String, [ColdSession])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        var dict: [(String, [ColdSession])] = []
        var seen: [String: Int] = [:]
        for item in items {
            let key = Calendar.current.isDateInToday(item.date) ? "Today" :
                      Calendar.current.isDateInYesterday(item.date) ? "Yesterday" :
                      formatter.string(from: item.date)
            if let idx = seen[key] {
                dict[idx].1.append(item)
            } else {
                seen[key] = dict.count
                dict.append((key, [item]))
            }
        }
        return dict
    }
}

// MARK: - SessionRow

struct SessionRow: View {
    let session: ColdSession

    var body: some View {
        HStack(spacing: 10) {
            Text(session.type.icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.type.rawValue)
                        .font(.headline)
                    Spacer()
                    Text(session.durationFormatted)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if let _ = session.temperatureCelsius {
                        Label(session.temperatureFormatted, systemImage: "thermometer")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    moodDeltaView
                    if !session.notes.isEmpty {
                        Text(session.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var moodDeltaView: some View {
        let delta = session.moodDelta
        if delta != 0 {
            Label(delta > 0 ? "+\(delta)" : "\(delta)",
                  systemImage: delta > 0 ? "arrow.up" : "arrow.down")
                .font(.caption)
                .foregroundStyle(delta > 0 ? .green : .orange)
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let label: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon).font(.caption)
                Text(label).font(.caption.weight(selected ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selected ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AddSessionView

struct AddSessionView: View {
    @ObservedObject var store: ColdStore
    @Environment(\.dismiss) private var dismiss

    @State private var type: ExposureType = .coldShower
    @State private var durationMinutes: Int = 2
    @State private var durationSeconds: Int = 0
    @State private var hasTemperature = false
    @State private var temperatureCelsius: Double = 15
    @State private var moodBefore: Int = 3
    @State private var moodAfter: Int = 3
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    typePicker
                    durationRow
                    temperatureRow
                    moodRow
                    notesRow
                }
                .padding(24)
            }
            Divider()
            footer
        }
        .frame(width: 440, height: 520)
    }

    private var header: some View {
        HStack {
            Text("Log Cold Session")
                .font(.headline)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Type", systemImage: "drop.fill")
                .font(.subheadline.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(ExposureType.allCases, id: \.self) { t in
                    TypeCard(t: t, selected: type == t) { type = t }
                }
            }
        }
    }

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Duration", systemImage: "timer")
                .font(.subheadline.bold())
            HStack(spacing: 16) {
                Stepper("\(durationMinutes) min", value: $durationMinutes, in: 0...60)
                    .frame(maxWidth: 160)
                Stepper("\(durationSeconds) sec", value: $durationSeconds, in: 0...59, step: 5)
                    .frame(maxWidth: 160)
            }
        }
    }

    private var temperatureRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Temperature", systemImage: "thermometer")
                    .font(.subheadline.bold())
                Toggle("", isOn: $hasTemperature)
                    .labelsHidden()
            }
            if hasTemperature {
                HStack {
                    Slider(value: $temperatureCelsius, in: -5...25, step: 0.5)
                    Text(String(format: "%.1f°C", temperatureCelsius))
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
    }

    private var moodRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Mood", systemImage: "face.smiling")
                .font(.subheadline.bold())
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Before")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    MoodPicker(value: $moodBefore)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("After")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    MoodPicker(value: $moodAfter)
                }
                let delta = moodAfter - moodBefore
                if delta != 0 {
                    VStack(spacing: 2) {
                        Text(delta > 0 ? "+\(delta)" : "\(delta)")
                            .font(.title2.bold())
                            .foregroundStyle(delta > 0 ? .green : .orange)
                        Text("mood shift")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var notesRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.subheadline.bold())
            TextEditor(text: $notes)
                .font(.body)
                .frame(height: 64)
                .padding(6)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
        }
    }

    private var footer: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Button("Save Session") {
                let total = durationMinutes * 60 + durationSeconds
                let session = ColdSession(
                    type: type,
                    durationSeconds: max(total, 1),
                    temperatureCelsius: hasTemperature ? temperatureCelsius : nil,
                    moodBefore: moodBefore,
                    moodAfter: moodAfter,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                store.add(session)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}

// MARK: - TypeCard

struct TypeCard: View {
    let t: ExposureType
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(t.icon).font(.title2)
                Text(t.rawValue)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(8)
            .background(selected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MoodPicker

struct MoodPicker: View {
    @Binding var value: Int
    private let labels = ["😟", "😕", "😐", "🙂", "😄"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    value = i
                } label: {
                    Text(labels[i - 1])
                        .font(.title2)
                        .padding(4)
                        .background(value == i ? Color.accentColor.opacity(0.2) : Color.clear)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(value == i ? Color.accentColor : Color.clear, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
