import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        let entries = store.todayEntries
        Group {
            if entries.isEmpty {
                EmptyStateView(
                    icon: "bolt.slash",
                    title: "No check-ins yet today",
                    subtitle: "Head to \"Log Energy\" to record your first entry."
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        TodaySummaryCard(entries: entries, average: store.todayAverage ?? 0)
                        energyArcSection(entries: entries)
                        timelineSection(entries: entries)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Today")
    }

    private func energyArcSection(entries: [EnergyEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Energy Arc")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(entries) { entry in
                    let c = EnergyEntry.color(for: entry.level)
                    VStack(spacing: 4) {
                        Text(entry.levelEmoji).font(.caption2)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: c.r, green: c.g, blue: c.b))
                            .frame(height: CGFloat(entry.level) * 14)
                        Text(entry.date, style: .time)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
            .padding(.horizontal, 4)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func timelineSection(entries: [EnergyEntry]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Timeline")
                .font(.headline)
                .padding(.horizontal)

            ForEach(entries) { entry in
                TimelineRow(entry: entry)
            }
        }
    }
}

struct TodaySummaryCard: View {
    let entries: [EnergyEntry]
    let average: Double

    private var c: (r: Double, g: Double, b: Double) { EnergyEntry.color(for: Int(average.rounded())) }
    private var avgColor: Color { Color(red: c.r, green: c.g, blue: c.b) }

    var body: some View {
        HStack(spacing: 0) {
            summaryItem(
                top: String(format: "%.1f", average),
                bottom: "Avg Energy",
                color: avgColor
            )
            Divider().frame(height: 50)
            summaryItem(
                top: "\(entries.count)",
                bottom: "Check-ins",
                color: .primary
            )
            Divider().frame(height: 50)
            summaryItem(
                top: "\(entries.map(\.level).max() ?? 0)",
                bottom: "Peak Today",
                color: .blue
            )
            Divider().frame(height: 50)
            summaryItem(
                top: "\(entries.map(\.level).min() ?? 0)",
                bottom: "Low Today",
                color: .secondary
            )
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func summaryItem(top: String, bottom: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(top)
                .font(.title.bold())
                .foregroundStyle(color)
            Text(bottom)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimelineRow: View {
    let entry: EnergyEntry

    private var c: (r: Double, g: Double, b: Double) { EnergyEntry.color(for: entry.level) }
    private var color: Color { Color(red: c.r, green: c.g, blue: c.b) }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(entry.date, style: .time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .trailing)

            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.levelEmoji)
                    Text(entry.levelLabel)
                        .font(.headline)
                        .foregroundStyle(color)
                    Text("• Level \(entry.level)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !entry.factors.isEmpty {
                    Text(entry.factors.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
