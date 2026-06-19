import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showAddSheet = false
    @State private var filterType: WorkoutEntry.WorkoutType? = nil

    private var filteredEntries: [WorkoutEntry] {
        guard let filter = filterType else { return store.entries }
        return store.entries.filter { $0.workoutType == filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            statsBar
            Divider()
            filterBar
            Divider()

            if filteredEntries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        WorkoutRowView(entry: entry)
                    }
                    .onDelete { offsets in
                        let ids = Set(offsets.map { filteredEntries[$0].id })
                        store.delete(withIDs: ids)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("ExerciseLog")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Log Workout", systemImage: "plus.circle.fill")
                }
                .help("Log a new workout")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddWorkoutView(isPresented: $showAddSheet)
                .environmentObject(store)
        }
    }

    // MARK: - Subviews

    private var statsBar: some View {
        HStack(spacing: 28) {
            StatPill(
                icon: "calendar",
                label: "This Week",
                value: "\(store.thisWeekEntries.count)",
                unit: store.thisWeekEntries.count == 1 ? "session" : "sessions"
            )
            StatPill(
                icon: "clock",
                label: "Weekly Time",
                value: "\(store.weeklyMinutes)",
                unit: "min"
            )
            StatPill(
                icon: "flame.fill",
                label: "Streak",
                value: "\(store.streak)",
                unit: store.streak == 1 ? "day" : "days"
            )
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(label: "All", isSelected: filterType == nil) {
                    filterType = nil
                }
                ForEach(WorkoutEntry.WorkoutType.allCases, id: \.self) { type in
                    FilterChip(
                        label: "\(type.emoji) \(type.rawValue)",
                        isSelected: filterType == type
                    ) {
                        filterType = filterType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 44))
                .foregroundColor(Color.secondary.opacity(0.5))
            Text(filterType == nil
                 ? "No workouts logged yet"
                 : "No \(filterType!.rawValue) workouts")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Click + in the toolbar to log your first session")
                .font(.caption)
                .foregroundColor(Color.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
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
                .fontWeight(isSelected ? .medium : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct WorkoutRowView: View {
    let entry: WorkoutEntry

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Type icon bubble
            Text(entry.workoutType.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .center, spacing: 6) {
                    Text(entry.workoutType.rawValue)
                        .fontWeight(.medium)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text("\(entry.durationMinutes) min")
                        .foregroundColor(.secondary)
                    Spacer()
                    IntensityBadge(intensity: entry.intensity)
                }

                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundColor(Color.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct IntensityBadge: View {
    let intensity: WorkoutEntry.Intensity

    var body: some View {
        Text(intensity.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(intensity.color.opacity(0.15))
            .foregroundColor(intensity.color)
            .cornerRadius(4)
    }
}
