import SwiftUI

// MARK: - Helpers

func strainColor(_ level: Double) -> Color {
    switch level {
    case ..<1.5: return .green
    case ..<2.5: return Color(red: 0.45, green: 0.75, blue: 0.0)
    case ..<3.5: return .yellow
    case ..<4.5: return .orange
    default:     return .red
    }
}

func strainLabel(_ level: Int) -> String {
    switch level {
    case 1: return "None"
    case 2: return "Mild"
    case 3: return "Moderate"
    case 4: return "Heavy"
    case 5: return "Strained"
    default: return ""
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var store = VoiceStore()
    @State private var showingAdd = false
    @State private var filterType: SessionType? = nil

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    var filteredEntries: [VoiceEntry] {
        guard let filter = filterType else { return store.entries }
        return store.entries.filter { $0.sessionType == filter }
    }

    var groupedEntries: [(key: String, value: [VoiceEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) {
            Self.dayFormatter.string(from: $0.date)
        }
        return grouped
            .sorted { a, b in
                let aDate = a.value.map(\.date).max() ?? .distantPast
                let bDate = b.value.map(\.date).max() ?? .distantPast
                return aDate > bDate
            }
            .map { (key: $0.key, value: $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        VStack(spacing: 0) {
            statsHeader
            Divider()
            filterBar
            Divider()

            if filteredEntries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
        .frame(minWidth: 520, minHeight: 480)
        .navigationTitle("VoiceLog")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Label("Log Session", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEntryView { store.add($0) }
        }
    }

    // MARK: Stats header

    var statsHeader: some View {
        HStack(spacing: 28) {
            statBadge(
                icon: "mic.fill", color: .purple,
                value: "\(store.todayEntries.count)",
                label: "Sessions Today"
            )
            statBadge(
                icon: "clock.fill", color: .blue,
                value: "\(store.todayTotalMinutes) min",
                label: "Voice Time Today"
            )
            statBadge(
                icon: "waveform", color: strainColor(store.todayAvgStrain),
                value: store.todayAvgStrain == 0 ? "–" : String(format: "%.1f", store.todayAvgStrain),
                label: "Avg Strain (1–5)"
            )
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    func statBadge(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.title2.bold())
                Text(label).font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: Filter bar

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip(label: "All", type: nil)
                ForEach(SessionType.allCases) { type in
                    chip(label: type.rawValue, type: type)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    func chip(label: String, type: SessionType?) -> some View {
        let active = filterType == type
        return Button { filterType = type } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(active ? Color.accentColor : Color(nsColor: .controlColor))
                .foregroundColor(active ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Empty state

    var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "mic.slash")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text("No sessions logged yet")
                .font(.headline)
            Text("Tap + to record your first voice session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: Entry list

    var entryList: some View {
        List {
            ForEach(groupedEntries, id: \.key) { group in
                Section(group.key) {
                    ForEach(group.value) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete { offsets in
                        let ids = Set(offsets.map { group.value[$0].id })
                        store.delete(ids: ids)
                    }
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}

// MARK: - EntryRow

struct EntryRow: View {
    let entry: VoiceEntry

    var body: some View {
        HStack(spacing: 12) {
            typeIcon
            details
            Spacer()
            strainIndicator
        }
        .padding(.vertical, 4)
    }

    var typeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(entry.sessionType.color.opacity(0.15))
                .frame(width: 38, height: 38)
            Image(systemName: entry.sessionType.icon)
                .foregroundColor(entry.sessionType.color)
                .font(.body)
        }
    }

    var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(entry.sessionType.rawValue)
                .font(.body.weight(.semibold))

            HStack(spacing: 5) {
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Text("\(entry.durationMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if entry.warmUpDone {
                    Label("Warmed up", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                if !entry.hydrated {
                    Label("Not hydrated", systemImage: "drop.slash.fill")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    var strainIndicator: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= entry.strainLevel
                              ? strainColor(Double(entry.strainLevel))
                              : Color.gray.opacity(0.2))
                        .frame(width: 7, height: 7)
                }
            }
            Text(strainLabel(entry.strainLevel))
                .font(.system(size: 9))
                .foregroundColor(strainColor(Double(entry.strainLevel)))
        }
    }
}

// MARK: - AddEntryView

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (VoiceEntry) -> Void

    @State private var date             = Date()
    @State private var sessionType      = SessionType.singing
    @State private var durationMinutes  = 30
    @State private var strainLevel      = 2
    @State private var warmUpDone       = false
    @State private var hydrated         = true
    @State private var notes            = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
        }
        .frame(width: 460)
    }

    var header: some View {
        HStack {
            Text("Log Voice Session")
                .font(.title2.bold())
            Spacer()
            Button("Cancel") { dismiss() }
            Button("Save") { save() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    var form: some View {
        Form {
            Section("Session Details") {
                DatePicker("Date & Time", selection: $date)

                Picker("Session Type", selection: $sessionType) {
                    ForEach(SessionType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }

                Stepper("Duration: \(durationMinutes) min",
                        value: $durationMinutes, in: 5...360, step: 5)
            }

            Section("Vocal Health") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vocal Strain Level")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 0) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                strainLevel = level
                            } label: {
                                Text(strainLabel(level))
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        strainLevel == level
                                            ? strainColor(Double(level))
                                            : Color(nsColor: .controlColor)
                                    )
                                    .foregroundColor(strainLevel == level ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.25)))
                }

                Toggle("Vocal warm-up done before session", isOn: $warmUpDone)
                Toggle("Stayed hydrated during session", isOn: $hydrated)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 60)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
            }
        }
        .formStyle(.grouped)
    }

    private func save() {
        let entry = VoiceEntry(
            date: date,
            sessionType: sessionType,
            durationMinutes: durationMinutes,
            strainLevel: strainLevel,
            warmUpDone: warmUpDone,
            hydrated: hydrated,
            notes: notes
        )
        onSave(entry)
        dismiss()
    }
}
