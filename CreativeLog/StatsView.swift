import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var store: SessionStore

    private var totalHours: Double { Double(store.totalMinutes) / 60.0 }
    private var avgFlowLevel: Double {
        guard !store.sessions.isEmpty else { return 0 }
        return Double(store.sessions.reduce(0) { $0 + $1.flowLevel }) / Double(store.sessions.count)
    }
    private var typeBreakdown: [(CreativeType, Int)] { store.minutesByType() }
    private var weeklyData: [(Date, Int)] { store.sessionsLast7Days() }

    private let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "E"; return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Overview").font(.title2).fontWeight(.semibold)

                // Summary cards
                HStack(spacing: 12) {
                    StatCard(icon: "bolt.fill", color: .purple,
                             value: "\(store.sessions.count)", label: "Sessions")
                    StatCard(icon: "clock.fill", color: .blue,
                             value: String(format: "%.1f h", totalHours), label: "Total Time")
                    StatCard(icon: "flame.fill", color: .orange,
                             value: "\(store.currentStreak)", label: "Day Streak")
                    StatCard(icon: "waveform", color: .green,
                             value: String(format: "%.1f", avgFlowLevel), label: "Avg Flow")
                }

                // Weekly bar chart
                GroupBox("Last 7 Days — Minutes") {
                    if weeklyData.allSatisfy({ $0.1 == 0 }) {
                        Text("No sessions in the last 7 days.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Chart {
                            ForEach(weeklyData, id: \.0) { (date, mins) in
                                BarMark(
                                    x: .value("Day", dayFmt.string(from: date)),
                                    y: .value("Minutes", mins)
                                )
                                .foregroundStyle(Color.accentColor.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .chartYAxisLabel("minutes")
                        .frame(height: 160)
                        .padding(.top, 6)
                    }
                }

                // Breakdown by type
                GroupBox("Time by Creative Type") {
                    if typeBreakdown.isEmpty {
                        Text("No sessions logged yet.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(typeBreakdown, id: \.0) { type, mins in
                                TypeRow(type: type, minutes: mins, total: store.totalMinutes)
                            }
                        }
                        .padding(.top, 6)
                    }
                }

                // Top projects
                let topProjects = topProjectsList()
                if !topProjects.isEmpty {
                    GroupBox("Top Projects") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(topProjects.prefix(5), id: \.0) { project, mins in
                                HStack {
                                    Text(project)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(formatMins(mins))
                                        .foregroundStyle(.secondary)
                                        .font(.callout)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .navigationTitle("Stats")
    }

    private func topProjectsList() -> [(String, Int)] {
        var map: [String: Int] = [:]
        for s in store.sessions { map[s.project, default: 0] += s.durationMinutes }
        return map.sorted { $0.value > $1.value }
    }

    private func formatMins(_ mins: Int) -> String {
        if mins < 60 { return "\(mins)m" }
        let h = mins / 60; let m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

struct StatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value)
                .font(.title2).fontWeight(.bold).monospacedDigit()
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

struct TypeRow: View {
    let type: CreativeType
    let minutes: Int
    let total: Int

    private var fraction: Double {
        total == 0 ? 0 : Double(minutes) / Double(total)
    }

    private var formattedTime: String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60; let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(type.emoji)
                Text(type.rawValue).fontWeight(.medium)
                Spacer()
                Text(formattedTime)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .monospacedDigit()
                Text(String(format: "%.0f%%", fraction * 100))
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                    .frame(width: 36, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.4))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.accentColor.gradient)
                        .frame(width: geo.size.width * CGFloat(fraction), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
