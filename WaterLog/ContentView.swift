import SwiftUI

struct ContentView: View {
    @StateObject private var store = WaterStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "drop.fill") }
                .tag(0)
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
        .environmentObject(store)
        .frame(minWidth: 480, minHeight: 560)
    }
}

// MARK: - Today Tab

struct TodayView: View {
    @EnvironmentObject var store: WaterStore
    @State private var showingAdd = false
    @State private var quickAmounts = [150, 200, 250, 350, 500]

    var body: some View {
        VStack(spacing: 0) {
            // Progress header
            VStack(spacing: 10) {
                Text("Hydration Today")
                    .font(.title2).fontWeight(.semibold)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(store.todayTotalML)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("/ \(store.dailyGoalML) mL")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: store.goalProgress)
                    .progressViewStyle(WaterProgressStyle(color: progressColor))
                    .frame(height: 18)

                Text(statusMessage)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Quick-add buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Add")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(quickAmounts, id: \.self) { ml in
                            Button {
                                store.add(amountML: ml)
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "drop.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                    Text("\(ml) mL")
                                        .font(.callout).fontWeight(.medium)
                                }
                                .frame(width: 72, height: 60)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            showingAdd = true
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                Text("Custom")
                                    .font(.callout).fontWeight(.medium)
                            }
                            .frame(width: 72, height: 60)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 10)

            Divider()

            // Today's log
            if store.todayEntries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "drop")
                        .font(.system(size: 44))
                        .foregroundColor(.blue.opacity(0.4))
                    Text("No entries yet today")
                        .foregroundColor(.secondary)
                    Text("Tap a quick-add button above to log your first drink.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.todayEntries) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete { idx in
                        let sorted = store.todayEntries
                        idx.forEach { store.delete(sorted[$0]) }
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEntrySheet()
        }
    }

    private var progressColor: Color {
        switch store.goalProgress {
        case ..<0.4: return .orange
        case ..<0.7: return .yellow
        default: return .blue
        }
    }

    private var statusMessage: String {
        let remaining = store.dailyGoalML - store.todayTotalML
        if remaining <= 0 { return "Goal reached! Great job staying hydrated." }
        return "\(remaining) mL to reach your daily goal"
    }
}

struct WaterProgressStyle: ProgressViewStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 14)
                    .animation(.spring(), value: configuration.fractionCompleted)
            }
        }
    }
}

struct EntryRow: View {
    let entry: WaterEntry

    var body: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundColor(.blue)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.amountML) mL")
                    .fontWeight(.semibold)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(entry.timeString)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Entry Sheet

struct AddEntrySheet: View {
    @EnvironmentObject var store: WaterStore
    @Environment(\.dismiss) var dismiss
    @State private var amountText = ""
    @State private var note = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Log Water Intake")
                .font(.title3).fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Amount (mL)").font(.callout).foregroundColor(.secondary)
                TextField("e.g. 300", text: $amountText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Note (optional)").font(.callout).foregroundColor(.secondary)
                TextField("e.g. morning glass, protein shake…", text: $note)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Add Entry") {
                    if let ml = Int(amountText), ml > 0 {
                        store.add(amountML: ml, note: note)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(Int(amountText).map { $0 <= 0 } ?? true)
            }
        }
        .padding(24)
        .frame(width: 340)
    }
}

// MARK: - History Tab

struct HistoryView: View {
    @EnvironmentObject var store: WaterStore

    var groupedEntries: [(String, [WaterEntry])] {
        let cal = Calendar.current
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none

        let grouped = Dictionary(grouping: store.entries) { entry in
            cal.startOfDay(for: entry.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (df.string(from: $0.key), $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        Group {
            if store.entries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No history yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedEntries, id: \.0) { day, entries in
                        Section {
                            ForEach(entries) { entry in
                                EntryRow(entry: entry)
                            }
                        } header: {
                            HStack {
                                Text(day).fontWeight(.semibold)
                                Spacer()
                                let total = entries.reduce(0) { $0 + $1.amountML }
                                Text("\(total) mL total")
                                    .foregroundColor(total >= store.dailyGoalML ? .green : .secondary)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

// MARK: - Settings Tab

struct SettingsView: View {
    @EnvironmentObject var store: WaterStore
    @State private var goalText = ""

    var body: some View {
        Form {
            Section("Daily Goal") {
                HStack {
                    TextField("mL", text: $goalText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("mL / day")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Save") {
                        if let ml = Int(goalText), ml >= 100 {
                            store.setGoal(ml)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(Int(goalText).map { $0 < 100 } ?? true)
                }
                Text("Recommended: 2000–3000 mL for most adults.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Quick Reference") {
                LabeledContent("Small glass", value: "~150 mL")
                LabeledContent("Standard glass", value: "~250 mL")
                LabeledContent("Large glass", value: "~350 mL")
                LabeledContent("Standard bottle", value: "~500 mL")
                LabeledContent("Large bottle", value: "~750 mL")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            goalText = "\(store.dailyGoalML)"
        }
    }
}
