import SwiftUI

struct ContentView: View {
    @StateObject private var store = SessionStore()
    @State private var showAdd = false
    @State private var selectedSession: MeditationSession?
    @State private var filterType: MeditationType? = nil

    private var filtered: [MeditationSession] {
        guard let f = filterType else { return store.sessions }
        return store.sessions.filter { $0.type == f }
    }

    var body: some View {
        HSplitView {
            // Left: stats + history
            VStack(spacing: 0) {
                StatsBar(store: store)
                Divider()
                FilterBar(selected: $filterType)
                Divider()
                SessionList(sessions: filtered, selected: $selectedSession, onDelete: store.delete)
            }
            .frame(minWidth: 340, idealWidth: 400)

            // Right: detail or empty state
            Group {
                if let session = selectedSession {
                    SessionDetailView(session: session)
                } else {
                    EmptyDetailView()
                }
            }
            .frame(minWidth: 340, idealWidth: 380)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    Label("Log Session", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .navigationTitle("MeditationLog")
        .sheet(isPresented: $showAdd) {
            AddSessionView().environmentObject(store)
        }
    }
}

// MARK: - Stats Bar

private struct StatsBar: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(store.totalSessions)", label: "Sessions")
            Divider().frame(height: 36)
            StatCell(value: formatMinutes(store.totalMinutes), label: "Total Time")
            Divider().frame(height: 36)
            StatCell(value: "\(store.currentStreak)d", label: "Streak")
            Divider().frame(height: 36)
            StatCell(
                value: store.averageCalmnessDelta >= 0
                    ? "+\(String(format: "%.1f", store.averageCalmnessDelta))"
                    : String(format: "%.1f", store.averageCalmnessDelta),
                label: "Avg Calm ↑",
                color: store.averageCalmnessDelta >= 0 ? .green : .orange
            )
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func formatMinutes(_ m: Int) -> String {
        if m < 60 { return "\(m)m" }
        let h = m / 60, rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }
}

private struct StatCell: View {
    let value: String
    let label: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Bar

private struct FilterBar: View {
    @Binding var selected: MeditationType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(label: "All", symbol: "square.grid.2x2", active: selected == nil) {
                    selected = nil
                }
                ForEach(MeditationType.allCases, id: \.self) { t in
                    FilterChip(label: t.rawValue, symbol: t.symbol, active: selected == t) {
                        selected = selected == t ? nil : t
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let symbol: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: symbol).font(.caption)
                Text(label).font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(active ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
            .overlay(
                Capsule().stroke(active ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session List

private struct SessionList: View {
    let sessions: [MeditationSession]
    @Binding var selected: MeditationSession?
    let onDelete: (IndexSet) -> Void

    var body: some View {
        if sessions.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "leaf")
                    .font(.system(size: 44))
                    .foregroundStyle(.green.opacity(0.5))
                Text("No sessions yet")
                    .foregroundStyle(.secondary)
                Text("Press ⌘N to log your first meditation.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(sessions, selection: $selected) { session in
                SessionRow(session: session)
                    .tag(session)
            }
            .listStyle(.inset)
        }
    }
}

private struct SessionRow: View {
    let session: MeditationSession

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: session.type.symbol)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.type.rawValue)
                        .font(.callout.bold())
                    Spacer()
                    Text("\(session.durationMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(session.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    let d = session.calmnessDelta
                    if d != 0 {
                        Text(d > 0 ? "+\(d) calm" : "\(d) calm")
                            .font(.caption2.bold())
                            .foregroundStyle(d > 0 ? .green : .orange)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Detail View

private struct SessionDetailView: View {
    let session: MeditationSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                HStack(spacing: 14) {
                    Image(systemName: session.type.symbol)
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.type.rawValue)
                            .font(.title2.bold())
                        Text(session.date.formatted(date: .long, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 4)

                DetailCard {
                    DetailRow(icon: "timer", label: "Duration", value: "\(session.durationMinutes) minutes")
                    Divider()
                    DetailRow(icon: "circle.fill", label: "Calmness before", value: "\(session.calmnessBefore)/5 — \(calmnessLabel(session.calmnessBefore))")
                    Divider()
                    DetailRow(icon: "circle.fill", label: "Calmness after", value: "\(session.calmnessAfter)/5 — \(calmnessLabel(session.calmnessAfter))")
                    Divider()
                    let d = session.calmnessDelta
                    DetailRow(
                        icon: d >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                        label: "Net change",
                        value: d == 0 ? "No change" : (d > 0 ? "+\(d) more calm" : "\(d) less calm"),
                        valueColor: d > 0 ? .green : d < 0 ? .orange : .secondary
                    )
                }

                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notes", systemImage: "text.quote")
                            .font(.caption.uppercaseSmallCaps())
                            .foregroundStyle(.secondary)
                        Text(session.notes)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
            .padding(20)
        }
    }

    private func calmnessLabel(_ v: Int) -> String {
        switch v {
        case 1: return "Anxious"
        case 2: return "Restless"
        case 3: return "Neutral"
        case 4: return "Calm"
        case 5: return "Serene"
        default: return ""
        }
    }
}

private struct DetailCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
    }
}

private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Empty detail

private struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green.opacity(0.4))
            Text("Select a session to view details")
                .foregroundStyle(.secondary)
            Text("or press ⌘N to log a new one.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}
