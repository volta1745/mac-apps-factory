import SwiftUI

// MARK: - Navigation

enum NavSelection: String, Hashable {
    case today, history, settings
}

// MARK: - Root

struct ContentView: View {
    @StateObject private var store = SpendStore()
    @State private var selection: NavSelection? = .today
    @State private var showAdd = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Today",    systemImage: "calendar.badge.clock")
                    .tag(NavSelection.today)
                Label("History",  systemImage: "clock.arrow.circlepath")
                    .tag(NavSelection.history)
                Label("Settings", systemImage: "gearshape")
                    .tag(NavSelection.settings)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 200)
        } detail: {
            switch selection {
            case .history:
                HistoryView(store: store)
            case .settings:
                SettingsView(store: store)
            default:
                TodayView(store: store, showAdd: $showAdd)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEntryView(store: store)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Log a purchase")
            }
        }
    }
}

// MARK: - Today

struct TodayView: View {
    @ObservedObject var store: SpendStore
    @Binding var showAdd: Bool

    private var ringColor: Color {
        let pct = store.dailyBudget > 0 ? store.todayTotal / store.dailyBudget : 0
        if pct >= 1.0 { return .red }
        if pct >= 0.8 { return .orange }
        return .green
    }

    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .full; return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ─────────────────────────────────────────────
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFmt.string(from: Date()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", store.todayTotal))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text(String(format: "of $%.2f daily budget", store.dailyBudget))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                BudgetRing(
                    fraction: store.dailyBudget > 0
                        ? min(store.todayTotal / store.dailyBudget, 1.0)
                        : 0,
                    color: ringColor
                )
            }
            .padding(20)
            .background(Color(.controlBackgroundColor))

            Divider()

            if store.todayEntries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        CategoryBreakdown(entries: store.todayEntries)
                            .padding()

                        Divider()

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Purchases")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 12)
                                .padding(.bottom, 6)

                            ForEach(store.todayEntries) { entry in
                                EntryRow(entry: entry) { store.delete(entry) }
                                Divider().padding(.leading, 52)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .navigationTitle("Today")
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No spending logged today")
                .font(.title3)
                .foregroundColor(.secondary)
            Button("Log a Purchase") { showAdd = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Budget Ring

struct BudgetRing: View {
    let fraction: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.4), value: fraction)
                Text("\(Int(fraction * 100))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .frame(width: 64, height: 64)
            Text("used")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Category Breakdown

struct CategoryBreakdown: View {
    let entries: [SpendEntry]

    private var totals: [(SpendEntry.Category, Double)] {
        var map: [SpendEntry.Category: Double] = [:]
        for e in entries { map[e.category, default: 0] += e.amount }
        return map.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By Category")
                .font(.headline)

            ForEach(totals, id: \.0) { cat, total in
                HStack(spacing: 10) {
                    Image(systemName: cat.icon)
                        .frame(width: 22)
                        .foregroundColor(.accentColor)
                    Text(cat.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "$%.2f", total))
                        .font(.subheadline)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: SpendEntry
    let onDelete: () -> Void

    private let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.category.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category.rawValue)
                    .font(.subheadline)
                    .bold()
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(timeFmt.string(from: entry.date))
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }

            Spacer()

            Text(String(format: "$%.2f", entry.amount))
                .font(.title3)
                .bold()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete entry")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - History

struct HistoryView: View {
    @ObservedObject var store: SpendStore

    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    var body: some View {
        Group {
            if store.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No entries yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.groupedByDay, id: \.key) { day, dayEntries in
                        Section {
                            ForEach(dayEntries) { entry in
                                EntryRow(entry: entry) { store.delete(entry) }
                            }
                        } header: {
                            HStack {
                                Text(dateFmt.string(from: day))
                                    .font(.headline)
                                Spacer()
                                let dayTotal = dayEntries.reduce(0.0) { $0 + $1.amount }
                                Text(String(format: "$%.2f", dayTotal))
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("History")
    }
}

// MARK: - Settings

struct SettingsView: View {
    @ObservedObject var store: SpendStore
    @State private var budgetStr: String = ""
    @State private var budgetError = false

    var body: some View {
        Form {
            Section("Daily Budget") {
                HStack {
                    Text("$")
                    TextField("e.g. 50.00", text: $budgetStr)
                        .onAppear { budgetStr = String(format: "%.2f", store.dailyBudget) }
                        .onSubmit { applyBudget() }
                    Button("Apply") { applyBudget() }
                        .buttonStyle(.bordered)
                }
                if budgetError {
                    Text("Enter a positive number.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section("All-time Stats") {
                LabeledContent("Total Entries",   value: "\(store.entries.count)")
                LabeledContent("Total Spent",     value: String(format: "$%.2f", store.allTimeTotal))
                LabeledContent("Days Tracked",    value: "\(store.groupedByDay.count)")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }

    private func applyBudget() {
        if let v = Double(budgetStr), v > 0 {
            store.dailyBudget = v
            budgetError = false
        } else {
            budgetError = true
        }
    }
}

// MARK: - Add Entry Sheet

struct AddEntryView: View {
    @ObservedObject var store: SpendStore
    @Environment(\.dismiss) private var dismiss

    @State private var amountStr: String = ""
    @State private var category: SpendEntry.Category = .food
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var showAmountError = false

    private var amountIsValid: Bool {
        if let v = Double(amountStr), v > 0 { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Sheet header ───────────────────────────────────────
            HStack {
                Text("Log Purchase")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            Form {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.title)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountStr)
                            .font(.title)
                            .onChange(of: amountStr) { _ in showAmountError = false }
                    }
                    if showAmountError {
                        Text("Enter a valid amount greater than zero.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(SpendEntry.Category.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 420)
    }

    private func save() {
        guard let amt = Double(amountStr), amt > 0 else {
            showAmountError = true
            return
        }
        store.add(SpendEntry(date: date, amount: amt, category: category, note: note))
        dismiss()
    }
}
