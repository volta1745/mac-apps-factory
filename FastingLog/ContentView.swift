import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: FastingStore
    @State private var showHistory = false

    var body: some View {
        NavigationSplitView {
            SidebarView(showHistory: $showHistory)
                .frame(minWidth: 220)
        } detail: {
            if showHistory {
                HistoryView()
            } else {
                ActiveFastView()
            }
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var store: FastingStore
    @Binding var showHistory: Bool

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $showHistory) {
                Label("Timer", systemImage: "timer")
                    .tag(false)
                Label("History", systemImage: "calendar")
                    .tag(true)
            }
            .listStyle(.sidebar)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Stats")
                    .font(.headline)
                    .padding(.bottom, 2)

                StatRow(label: "Fasts logged", value: "\(store.completedEntries.count)")
                StatRow(label: "Goal met", value: "\(store.goalMetCount)")
                StatRow(label: "Streak", value: "\(store.currentStreak) day\(store.currentStreak == 1 ? "" : "s")")
                StatRow(label: "Avg fast", value: store.averageFastHours > 0 ? String(format: "%.1f h", store.averageFastHours) : "—")
                StatRow(label: "Longest", value: store.longestFastHours > 0 ? String(format: "%.1f h", store.longestFastHours) : "—")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("FastingLog")
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
        }
    }
}

// MARK: - Active Fast Timer

struct ActiveFastView: View {
    @EnvironmentObject var store: FastingStore
    @State private var now = Date()
    @State private var showEndSheet = false
    @State private var showCancelAlert = false
    @State private var endNotes = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            if let fast = store.activeFast {
                ActiveTimerPanel(fast: fast, now: now, onEnd: { showEndSheet = true }, onCancel: { showCancelAlert = true })
            } else {
                IdlePanel()
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(timer) { _ in now = Date() }
        .sheet(isPresented: $showEndSheet) {
            EndFastSheet(notes: $endNotes) {
                store.endFast(notes: endNotes)
                endNotes = ""
                showEndSheet = false
            } onCancel: {
                showEndSheet = false
            }
        }
        .alert("Cancel Fast?", isPresented: $showCancelAlert) {
            Button("Yes, Cancel Fast", role: .destructive) { store.cancelFast() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("This fast will not be saved to history.")
        }
    }
}

struct ActiveTimerPanel: View {
    let fast: FastingEntry
    let now: Date
    let onEnd: () -> Void
    let onCancel: () -> Void

    private var elapsed: TimeInterval { now.timeIntervalSince(fast.startTime) }
    private var goal: TimeInterval { fast.goalHours * 3600 }
    private var progress: Double { min(elapsed / goal, 1.0) }
    private var goalMet: Bool { elapsed >= goal }

    var body: some View {
        VStack(spacing: 24) {
            Text("Fasting in progress")
                .font(.title2.bold())

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        goalMet ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(formatDuration(elapsed))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                    Text("of \(fast.goalHours, specifier: "%.0f") h goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if goalMet {
                        Text("Goal reached!")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
            }

            VStack(spacing: 6) {
                InfoRow(label: "Protocol", value: fast.protocol_.rawValue)
                InfoRow(label: "Started", value: fast.startTime.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Goal end", value: (fast.startTime + goal).formatted(date: .omitted, time: .shortened))
            }
            .padding(.horizontal, 60)

            HStack(spacing: 16) {
                Button("End Fast", action: onEnd)
                    .buttonStyle(.borderedProminent)
                    .tint(goalMet ? .green : .orange)

                Button("Cancel", role: .destructive, action: onCancel)
                    .buttonStyle(.bordered)
            }
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
        .font(.callout)
    }
}

// MARK: - Idle Panel

struct IdlePanel: View {
    @EnvironmentObject var store: FastingStore

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("No active fast")
                .font(.title2.bold())

            Text("Choose a protocol and start your fast.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Protocol")
                    .font(.headline)

                Picker("Protocol", selection: $store.selectedProtocol) {
                    ForEach(FastingProtocol.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(store.selectedProtocol.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if store.selectedProtocol == .custom {
                    HStack {
                        Text("Goal: \(store.customGoalHours, specifier: "%.0f") hours")
                        Spacer()
                        Stepper("", value: $store.customGoalHours, in: 1...36, step: 1)
                            .labelsHidden()
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 400)

            Button("Start Fast Now") {
                store.startFast()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)
        }
    }
}

// MARK: - End Fast Sheet

struct EndFastSheet: View {
    @Binding var notes: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("End Fast")
                .font(.title2.bold())

            Text("Add an optional note before saving this fast to history.")
                .foregroundStyle(.secondary)
                .font(.callout)

            TextEditor(text: $notes)
                .font(.body)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
                .overlay(
                    Group {
                        if notes.isEmpty {
                            Text("Optional notes…")
                                .foregroundStyle(.tertiary)
                                .padding(6)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                )

            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                Spacer()
                Button("Save Fast", action: onSave)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

// MARK: - History

struct HistoryView: View {
    @EnvironmentObject var store: FastingStore
    @State private var filterProtocol: FastingProtocol? = nil

    var filtered: [FastingEntry] {
        store.completedEntries.filter { entry in
            filterProtocol == nil || entry.protocol_ == filterProtocol
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Fast History")
                    .font(.title2.bold())
                Spacer()
                Picker("Filter", selection: $filterProtocol) {
                    Text("All").tag(Optional<FastingProtocol>.none)
                    ForEach(FastingProtocol.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(Optional(p))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
            }
            .padding()

            Divider()

            if filtered.isEmpty {
                Spacer()
                Text("No fasts recorded yet.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(filtered) { entry in
                        FastingEntryRow(entry: entry)
                    }
                    .onDelete { offsets in
                        let idsToDelete = offsets.map { filtered[$0].id }
                        let indices = store.entries.indices.filter { idsToDelete.contains(store.entries[$0].id) }
                        store.delete(at: IndexSet(indices))
                    }
                }
            }
        }
    }
}

struct FastingEntryRow: View {
    let entry: FastingEntry

    private var durationText: String {
        guard let dur = entry.duration else { return "—" }
        let h = Int(dur) / 3600
        let m = (Int(dur) % 3600) / 60
        return String(format: "%dh %02dm", h, m)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.callout.bold())
                    if entry.goalMet {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(durationText)
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundColor(entry.goalMet ? .green : .primary)

                Text(entry.protocol_.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
