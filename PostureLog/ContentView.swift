import SwiftUI

struct ContentView: View {
    @StateObject private var store = PostureStore()
    @State private var showingAdd = false

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, showingAdd: $showingAdd)
                .navigationSplitViewColumnWidth(min: 190, ideal: 200)
        } detail: {
            HistoryView(store: store)
        }
        .sheet(isPresented: $showingAdd) {
            AddEntryView(store: store)
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @ObservedObject var store: PostureStore
    @Binding var showingAdd: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                Text("PostureLog")
                    .font(.title3.bold())
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            VStack(spacing: 8) {
                StatRow(icon: "checkmark.circle", label: "Today's Checks", value: "\(store.todayEntries.count)")
                StatRow(
                    icon: "chart.bar.fill",
                    label: "Avg Score",
                    value: store.todayEntries.isEmpty
                        ? "–"
                        : String(format: "%.1f / 3.0", store.todayAverageScore)
                )
                if let area = store.todayMostAffectedArea {
                    StatRow(icon: "bolt.heart", label: "Most Affected", value: area.rawValue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)

            if !store.todayEntries.isEmpty {
                Divider().padding(.top, 14)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Breakdown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    HStack(spacing: 8) {
                        RatingPill(label: "Good", count: store.todayGoodCount, color: .green)
                        RatingPill(label: "Fair", count: store.todayFairCount, color: .orange)
                        RatingPill(label: "Poor", count: store.todayPoorCount, color: .red)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }

            Spacer()

            Button {
                showingAdd = true
            } label: {
                Label("Log Posture Check", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(14)
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RatingPill: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.headline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - History

struct HistoryView: View {
    @ObservedObject var store: PostureStore

    var body: some View {
        if store.entries.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No Posture Checks Yet")
                    .font(.title3.bold())
                Text("Click 'Log Posture Check' to start tracking your posture throughout the day.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Posture History")
        } else {
            List {
                ForEach(store.entries) { entry in
                    EntryRow(entry: entry)
                        .padding(.vertical, 2)
                }
                .onDelete(perform: store.delete)
            }
            .navigationTitle("Posture History (\(store.entries.count) entries)")
        }
    }
}

struct EntryRow: View {
    let entry: PostureEntry

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.rating.systemImage)
                .font(.title2)
                .foregroundStyle(entry.rating.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(entry.rating.rawValue)
                        .font(.headline)
                        .foregroundStyle(entry.rating.color)

                    if entry.discomfortLevel > 0 {
                        Text("Discomfort \(entry.discomfortLevel)/5")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.12), in: Capsule())
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    Text(Self.formatter.string(from: entry.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !entry.affectedAreas.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.heart")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(entry.affectedAreas.map(\.rawValue).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if entry.correctiveAction != .none {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(entry.correctiveAction.rawValue)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

// MARK: - Add Entry

struct AddEntryView: View {
    @ObservedObject var store: PostureStore
    @Environment(\.dismiss) var dismiss

    @State private var rating: PostureRating = .good
    @State private var selectedAreas: Set<BodyArea> = []
    @State private var discomfortLevel: Int = 0
    @State private var correctiveAction: CorrectiveAction = .none
    @State private var notes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Log Posture Check")
                    .font(.title3.bold())
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.bar)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Rating picker
                    FormSection(title: "Posture Rating") {
                        HStack(spacing: 10) {
                            ForEach(PostureRating.allCases, id: \.self) { r in
                                RatingButton(
                                    rating: r,
                                    isSelected: rating == r,
                                    action: { rating = r }
                                )
                            }
                        }
                    }

                    // Affected areas
                    FormSection(title: "Affected Body Areas") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(BodyArea.allCases, id: \.self) { area in
                                Toggle(area.rawValue, isOn: Binding(
                                    get: { selectedAreas.contains(area) },
                                    set: { on in
                                        if on { selectedAreas.insert(area) } else { selectedAreas.remove(area) }
                                    }
                                ))
                            }
                        }
                    }

                    // Discomfort slider
                    FormSection(title: "Discomfort Level: \(discomfortLevel == 0 ? "None" : "\(discomfortLevel) / 5")") {
                        Slider(
                            value: Binding(
                                get: { Double(discomfortLevel) },
                                set: { discomfortLevel = Int($0.rounded()) }
                            ),
                            in: 0...5, step: 1
                        )
                        HStack {
                            Text("None").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("Severe").font(.caption2).foregroundStyle(.secondary)
                        }
                    }

                    // Corrective action
                    FormSection(title: "Corrective Action Taken") {
                        Picker("", selection: $correctiveAction) {
                            ForEach(CorrectiveAction.allCases, id: \.self) { action in
                                Text(action.rawValue).tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    // Notes
                    FormSection(title: "Notes (optional)") {
                        TextField("Any additional observations...", text: $notes, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Entry") {
                    let entry = PostureEntry(
                        rating: rating,
                        affectedAreas: Array(selectedAreas).sorted { $0.rawValue < $1.rawValue },
                        discomfortLevel: discomfortLevel,
                        correctiveAction: correctiveAction,
                        notes: notes
                    )
                    store.add(entry)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.bar)
        }
        .frame(width: 400, height: 560)
    }
}

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            content
        }
    }
}

struct RatingButton: View {
    let rating: PostureRating
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: rating.systemImage)
                    .font(.title2)
                Text(rating.rawValue)
                    .font(.callout.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : rating.color)
            .background(
                isSelected ? rating.color : rating.color.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
    }
}
