import SwiftUI

struct ContentView: View {
    @StateObject private var store = MealStore()
    @State private var showingAddSheet = false
    @State private var filterType: MealType? = nil

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } detail: {
            historyView
        }
        .frame(minWidth: 700, minHeight: 520)
        .sheet(isPresented: $showingAddSheet) {
            AddMealView(store: store)
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Stats header
            VStack(spacing: 12) {
                Text("🍽️ MealLog")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                statsGrid
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.5))

            Divider()

            // Filter
            VStack(alignment: .leading, spacing: 4) {
                Text("Filter by type")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 10)

                filterRow(nil, label: "All Meals", emoji: "🍽️")
                ForEach(MealType.allCases, id: \.self) { type in
                    filterRow(type, label: type.rawValue, emoji: type.emoji)
                }
            }

            Spacer()

            Button(action: { showingAddSheet = true }) {
                Label("Log a Meal", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
    }

    private func filterRow(_ type: MealType?, label: String, emoji: String) -> some View {
        Button(action: { filterType = type }) {
            HStack {
                Text(emoji).font(.body)
                Text(label)
                    .font(.callout)
                Spacer()
                if filterType == type {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.accentColor)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(
                filterType == type
                    ? Color.accentColor.opacity(0.12)
                    : Color.clear
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    private var statsGrid: some View {
        HStack(spacing: 8) {
            statCard(value: "\(store.todayCount)", label: "Today")
            statCard(value: "\(store.entries.count)", label: "Total")
            statCard(
                value: store.weeklyAvgSatisfaction > 0
                    ? String(format: "%.1f", store.weeklyAvgSatisfaction)
                    : "—",
                label: "Avg Sat."
            )
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3).bold()
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: History

    private var filteredEntries: [MealEntry] {
        guard let f = filterType else { return store.entries }
        return store.entries.filter { $0.mealType == f }
    }

    private var filteredDays: [String] {
        Array(Set(filteredEntries.map(\.dayKey))).sorted(by: >)
    }

    private var historyView: some View {
        Group {
            if filteredEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 56))
                        .foregroundStyle(.tertiary)
                    Text("No meals logged yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Click \"Log a Meal\" to record your first entry.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                    Button("Log a Meal") { showingAddSheet = true }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredDays, id: \.self) { day in
                        Section(header: Text(formattedDay(day)).font(.headline)) {
                            let dayEntries = filteredEntries.filter { $0.dayKey == day }
                            ForEach(dayEntries) { entry in
                                MealRowView(entry: entry)
                            }
                            .onDelete { offsets in
                                store.delete(at: offsets, from: dayEntries)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle(filterType.map { $0.rawValue } ?? "All Meals")
    }

    private func formattedDay(_ key: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: key) else { return key }
        let display = DateFormatter()
        display.dateStyle = .full
        display.timeStyle = .none
        if Calendar.current.isDateInToday(date) { return "Today – \(display.string(from: date))" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday – \(display.string(from: date))" }
        return display.string(from: date)
    }
}

// MARK: - Meal Row

struct MealRowView: View {
    let entry: MealEntry

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: entry.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.mealType.emoji)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.mealType.rawValue)
                        .font(.headline)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(timeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(entry.foods)
                    .font(.body)
                    .lineLimit(2)

                HStack(spacing: 16) {
                    ratingLabel("Hunger", value: entry.hungerBefore, color: .orange)
                    ratingLabel("Satisfaction", value: entry.satisfactionAfter, color: .green)
                }

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func ratingLabel(_ title: String, value: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(title + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= value ? color : Color(.separatorColor))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Add Meal Sheet

struct AddMealView: View {
    @ObservedObject var store: MealStore
    @Environment(\.dismiss) private var dismiss

    @State private var mealType: MealType = .lunch
    @State private var foods: String = ""
    @State private var hungerBefore: Int = 3
    @State private var satisfactionAfter: Int = 3
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @FocusState private var foodsFieldFocused: Bool

    private var canSave: Bool { !foods.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Log a Meal")
                    .font(.title2).bold()
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.5))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Meal type picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Meal Type", systemImage: "fork.knife")
                            .font(.headline)
                        HStack(spacing: 8) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                typeButton(type)
                            }
                        }
                    }

                    // What did you eat
                    VStack(alignment: .leading, spacing: 8) {
                        Label("What did you eat?", systemImage: "list.bullet")
                            .font(.headline)
                        TextEditor(text: $foods)
                            .font(.body)
                            .frame(height: 72)
                            .padding(6)
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separatorColor)))
                            .focused($foodsFieldFocused)
                    }

                    // Hunger before
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Hunger level before eating", systemImage: "bolt.fill")
                            .font(.headline)
                        ratingPicker($hungerBefore, labels: ["Not hungry", "Peckish", "Moderate", "Hungry", "Starving"], color: .orange)
                    }

                    // Satisfaction after
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Satisfaction after eating", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                        ratingPicker($satisfactionAfter, labels: ["Still hungry", "Barely full", "Satisfied", "Full", "Stuffed"], color: .green)
                    }

                    // Time
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Time", systemImage: "clock")
                            .font(.headline)
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(.headline)
                        TextField("Any thoughts about this meal…", text: $notes)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Entry") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
            }
            .padding()
        }
        .frame(width: 480)
        .onAppear { foodsFieldFocused = true }
    }

    private func typeButton(_ type: MealType) -> some View {
        Button(action: { mealType = type }) {
            VStack(spacing: 4) {
                Text(type.emoji).font(.title2)
                Text(type.rawValue).font(.caption2)
            }
            .frame(width: 68, height: 52)
            .background(
                mealType == type
                    ? Color.accentColor.opacity(0.15)
                    : Color(.controlBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(mealType == type ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func ratingPicker(_ binding: Binding<Int>, labels: [String], color: Color) -> some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Button(action: { binding.wrappedValue = i }) {
                    VStack(spacing: 3) {
                        Circle()
                            .fill(i <= binding.wrappedValue ? color : Color(.separatorColor))
                            .frame(width: 22, height: 22)
                        Text("\(i)")
                            .font(.caption2)
                            .foregroundStyle(i <= binding.wrappedValue ? color : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .help(labels[i - 1])
            }
            Spacer()
            Text(labels[binding.wrappedValue - 1])
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        let entry = MealEntry(
            date: date,
            mealType: mealType,
            foods: foods.trimmingCharacters(in: .whitespacesAndNewlines),
            hungerBefore: hungerBefore,
            satisfactionAfter: satisfactionAfter,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.add(entry)
        dismiss()
    }
}
