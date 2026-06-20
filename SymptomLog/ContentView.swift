import SwiftUI

// MARK: - Constants

let predefinedSymptoms = [
    "Headache", "Fatigue", "Nausea", "Eye Strain", "Back Pain",
    "Neck Pain", "Shoulder Pain", "Stomach Ache", "Dizziness",
    "Muscle Ache", "Sore Throat", "Anxiety", "Brain Fog", "Joint Pain"
]

let bodyLocations = [
    "General", "Head", "Eyes", "Neck", "Throat",
    "Shoulders", "Chest", "Upper Back", "Lower Back",
    "Abdomen", "Arms / Hands", "Legs / Feet"
]

let severityLabels = ["", "Minimal", "Mild", "Moderate", "Severe", "Extreme"]
let severityColors: [Color] = [.clear, .green, Color(red: 0.7, green: 0.8, blue: 0.0), .orange, .red, .purple]

// MARK: - Root

struct ContentView: View {
    @StateObject private var store = SymptomStore()
    @State private var filterSymptom = "All"

    var body: some View {
        HSplitView {
            AddSymptomView(store: store)
                .frame(minWidth: 260, idealWidth: 280, maxWidth: 300)
                .padding(16)

            HistoryView(store: store, filterSymptom: $filterSymptom)
                .frame(minWidth: 400)
        }
        .frame(minWidth: 680, minHeight: 500)
    }
}

// MARK: - Add Symptom Panel

struct AddSymptomView: View {
    @ObservedObject var store: SymptomStore

    @State private var selectedSymptom = predefinedSymptoms[0]
    @State private var customSymptom = ""
    @State private var isCustom = false
    @State private var severity = 3
    @State private var bodyLocation = bodyLocations[0]
    @State private var logDate = Date()
    @State private var notes = ""
    @State private var showSuccess = false

    private var symptomName: String {
        isCustom ? customSymptom.trimmingCharacters(in: .whitespaces) : selectedSymptom
    }

    private var canLog: Bool {
        !symptomName.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Log Symptom")
                .font(.title2.bold())

            // Symptom
            Group {
                Label("Symptom", systemImage: "cross.case")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Enter custom symptom", isOn: $isCustom)
                    .toggleStyle(.checkbox)
                    .font(.callout)

                if isCustom {
                    TextField("e.g. Itchy eyes", text: $customSymptom)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Picker("", selection: $selectedSymptom) {
                        ForEach(predefinedSymptoms, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .labelsHidden()
                }
            }

            Divider()

            // Severity
            Group {
                HStack {
                    Label("Severity", systemImage: "waveform.path.ecg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(severityLabels[severity])
                        .font(.caption.bold())
                        .foregroundColor(severityColors[severity])
                }

                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            severity = level
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(severity >= level ? severityColors[level] : Color.secondary.opacity(0.15))
                                    .frame(width: 34, height: 34)
                                Text("\(level)")
                                    .font(.caption.bold())
                                    .foregroundColor(severity >= level ? .white : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: severity)
                    }
                }
            }

            Divider()

            // Body location
            Group {
                Label("Body Location", systemImage: "figure.stand")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $bodyLocation) {
                    ForEach(bodyLocations, id: \.self) { loc in
                        Text(loc).tag(loc)
                    }
                }
                .labelsHidden()
            }

            // When
            Group {
                Label("When", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DatePicker("", selection: $logDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            Divider()

            // Notes
            Group {
                Label("Notes (optional)", systemImage: "note.text")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $notes)
                    .font(.body)
                    .frame(height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )
            }

            Spacer(minLength: 4)

            // Log button + feedback
            VStack(spacing: 6) {
                Button(action: logEntry) {
                    Label("Log Symptom", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canLog)

                if showSuccess {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text("Logged!").foregroundColor(.green).font(.callout)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    private func logEntry() {
        let entry = SymptomEntry(
            date: logDate,
            symptom: symptomName,
            severity: severity,
            bodyLocation: bodyLocation,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        store.add(entry)
        notes = ""
        logDate = Date()
        withAnimation(.easeInOut) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut) { showSuccess = false }
        }
    }
}

// MARK: - History Panel

struct HistoryView: View {
    @ObservedObject var store: SymptomStore
    @Binding var filterSymptom: String

    private var uniqueSymptoms: [String] {
        Array(Set(store.entries.map(\.symptom))).sorted()
    }

    private var filteredEntries: [SymptomEntry] {
        filterSymptom == "All"
            ? store.entries
            : store.entries.filter { $0.symptom == filterSymptom }
    }

    private var todayCount: Int {
        let cal = Calendar.current
        return filteredEntries.filter { cal.isDateInToday($0.date) }.count
    }

    private var avgSeverity: String {
        let f = filteredEntries
        guard !f.isEmpty else { return "—" }
        let avg = Double(f.map(\.severity).reduce(0, +)) / Double(f.count)
        return String(format: "%.1f", avg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Toolbar row
            HStack {
                Text("History")
                    .font(.title2.bold())
                Spacer()
                Picker("Filter", selection: $filterSymptom) {
                    Text("All Symptoms").tag("All")
                    if !uniqueSymptoms.isEmpty {
                        Divider()
                        ForEach(uniqueSymptoms, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                }
                .frame(width: 180)
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 10)

            // Stats strip
            if !store.entries.isEmpty {
                HStack(spacing: 12) {
                    StatBadge(
                        icon: "list.bullet",
                        label: filterSymptom == "All" ? "Total" : filterSymptom,
                        value: "\(filteredEntries.count)"
                    )
                    StatBadge(icon: "calendar", label: "Today", value: "\(todayCount)")
                    StatBadge(
                        icon: "waveform.path.ecg",
                        label: "Avg Severity",
                        value: avgSeverity
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }

            Divider()

            if filteredEntries.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "cross.case")
                        .font(.system(size: 38))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(store.entries.isEmpty ? "No symptoms logged yet" : "No entries for this filter")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { i in
                            store.delete(id: filteredEntries[i].id)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

// MARK: - Subviews

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.headline)
                Text(label).font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }
}

struct EntryRow: View {
    let entry: SymptomEntry

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Severity dot
            ZStack {
                Circle()
                    .fill(severityColors[entry.severity])
                    .frame(width: 34, height: 34)
                Text("\(entry.severity)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.symptom)
                        .font(.headline)
                    if entry.bodyLocation != "General" {
                        Text(entry.bodyLocation)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.5))
                            .cornerRadius(4)
                    }
                }

                Text(Self.formatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(severityLabels[entry.severity])
                .font(.caption.bold())
                .foregroundColor(severityColors[entry.severity])
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(severityColors[entry.severity].opacity(0.12))
                .cornerRadius(5)
        }
        .padding(.vertical, 4)
    }
}
