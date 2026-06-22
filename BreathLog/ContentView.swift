import SwiftUI

struct ContentView: View {
    @StateObject private var store = BreathStore()
    @State private var filterTechnique: BreathTechnique? = nil
    @State private var showingAdd = false

    private var filtered: [BreathSession] {
        guard let t = filterTechnique else { return store.sessions }
        return store.sessions.filter { $0.technique == t }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            detail
        }
        .sheet(isPresented: $showingAdd) {
            AddSessionView(store: store)
        }
    }

    // MARK: – Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App title
            HStack(spacing: 8) {
                Image(systemName: "wind")
                    .font(.title2)
                    .foregroundStyle(.teal)
                Text("BreathLog")
                    .font(.title2).bold()
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 12)

            // Today stats
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY")
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        StatRow(label: "Sessions", value: "\(store.todaySessions.count)")
                        StatRow(label: "Minutes breathed", value: "\(store.todayTotalMinutes)")
                        StatRow(label: "Avg calm (all time)",
                                value: store.allTimeAvgCalm > 0
                                    ? String(format: "%.1f / 5", store.allTimeAvgCalm)
                                    : "—")
                        StatRow(label: "Avg stress reduction",
                                value: store.avgStressReduction != 0
                                    ? String(format: "%+.1f", store.avgStressReduction)
                                    : "—")
                    }
                }
                .padding(.horizontal)
            }

            Divider().padding(.vertical, 12)

            // Technique filter
            Text("TECHNIQUE")
                .font(.caption).bold()
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 2) {
                FilterRow(label: "All Techniques", icon: "list.bullet",
                          isSelected: filterTechnique == nil) {
                    filterTechnique = nil
                }
                ForEach(BreathTechnique.allCases, id: \.self) { t in
                    let count = store.sessions.filter { $0.technique == t }.count
                    FilterRow(label: t.rawValue, icon: t.icon,
                              badge: count > 0 ? "\(count)" : nil,
                              isSelected: filterTechnique == t) {
                        filterTechnique = (filterTechnique == t) ? nil : t
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Add button
            Button(action: { showingAdd = true }) {
                Label("Log Session", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.teal)
            .padding()
        }
    }

    // MARK: – Detail

    @ViewBuilder
    private var detail: some View {
        if filtered.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "wind")
                    .font(.system(size: 52))
                    .foregroundStyle(.teal.opacity(0.4))
                Text(store.sessions.isEmpty ? "No sessions yet" : "No sessions for this filter")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if store.sessions.isEmpty {
                    Text("Tap \"Log Session\" in the sidebar to record your first breathing exercise.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(filtered) { session in
                    SessionRow(session: session)
                        .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    let ids = Set(offsets.map { filtered[$0].id })
                    store.delete(ids: ids)
                }
            }
            .listStyle(.inset)
            .navigationTitle(filterTechnique?.rawValue ?? "All Sessions")
            .navigationSubtitle("\(filtered.count) session\(filtered.count == 1 ? "" : "s")")
        }
    }
}

// MARK: – Session Row

struct SessionRow: View {
    let session: BreathSession

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: session.date)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Technique icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.teal.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: session.technique.icon)
                    .foregroundStyle(.teal)
                    .font(.system(size: 18))
            }

            // Main info
            VStack(alignment: .leading, spacing: 3) {
                Text(session.technique.rawValue)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label("\(session.durationMinutes) min", systemImage: "clock")
                    Label("\(session.rounds) rounds", systemImage: "repeat")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Stress → Calm
            VStack(alignment: .trailing, spacing: 4) {
                Text(dateString)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                HStack(spacing: 4) {
                    StressChip(value: session.stressBefore, label: "before", color: .orange)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    StressChip(value: session.calmAfter, label: "after", color: .teal)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct StressChip: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(value)/5")
                .font(.caption2)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1), in: Capsule())
    }
}

// MARK: – Sidebar helpers

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
                .font(.caption.monospacedDigit())
                .bold()
        }
    }
}

struct FilterRow: View {
    let label: String
    let icon: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? .white : .secondary)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .primary)
                Spacer()
                if let b = badge {
                    Text(b)
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.teal : Color.clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
