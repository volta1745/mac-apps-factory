import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: SessionStore
    @State private var filterType: CreativeType? = nil
    @State private var searchText = ""

    private var filtered: [CreativeSession] {
        store.sessions.filter { session in
            let typeMatch = filterType == nil || session.type == filterType
            let searchMatch = searchText.isEmpty ||
                session.project.localizedCaseInsensitiveContains(searchText) ||
                session.notes.localizedCaseInsensitiveContains(searchText)
            return typeMatch && searchMatch
        }
    }

    private var grouped: [(String, [CreativeSession])] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateStyle = .full
        fmt.timeStyle = .none

        var dict: [String: [CreativeSession]] = [:]
        for s in filtered {
            let key: String
            if cal.isDateInToday(s.date) { key = "Today" }
            else if cal.isDateInYesterday(s.date) { key = "Yesterday" }
            else { key = fmt.string(from: s.date) }
            dict[key, default: []].append(s)
        }

        let order = filtered.map { s -> String in
            if cal.isDateInToday(s.date) { return "Today" }
            if cal.isDateInYesterday(s.date) { return "Yesterday" }
            return fmt.string(from: s.date)
        }
        var seen = Set<String>()
        let keys = order.filter { seen.insert($0).inserted }
        return keys.map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search projects or notes…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(Rectangle().frame(height: 1).foregroundStyle(Color(nsColor: .separatorColor)), alignment: .bottom)

            // Type filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(label: "All", emoji: "🗂", isSelected: filterType == nil) {
                        filterType = nil
                    }
                    ForEach(CreativeType.allCases) { type in
                        FilterChip(label: type.rawValue, emoji: type.emoji, isSelected: filterType == type) {
                            filterType = filterType == type ? nil : type
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .overlay(Rectangle().frame(height: 1).foregroundStyle(Color(nsColor: .separatorColor)), alignment: .bottom)

            // List
            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "tray").font(.largeTitle).foregroundStyle(.tertiary)
                    Text(store.sessions.isEmpty ? "No sessions logged yet." : "No sessions match.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(grouped, id: \.0) { (day, sessions) in
                        Section(day) {
                            ForEach(sessions) { session in
                                SessionRow(session: session)
                            }
                            .onDelete { offsets in
                                let indices = offsets.map { sessions[$0].id }
                                store.sessions.removeAll { indices.contains($0.id) }
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

struct FilterChip: View {
    let label: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji).font(.caption)
                Text(label).font(.caption).fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .quaternaryLabelColor).opacity(0.4))
            .cornerRadius(20)
            .overlay(
                Capsule().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SessionRow: View {
    let session: CreativeSession

    var body: some View {
        HStack(spacing: 12) {
            Text(session.type.emoji)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.project)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    Text(session.durationFormatted)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                HStack(spacing: 6) {
                    Text(session.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    FlowBadge(level: session.flowLevel, label: session.flowLabel)
                    Spacer()
                    Text(session.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FlowBadge: View {
    let level: Int
    let label: String

    private var color: Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .purple
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .font(.caption2)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(color)
        }
    }
}
