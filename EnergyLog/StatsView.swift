import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        Group {
            if store.entries.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.xaxis",
                    title: "No data yet",
                    subtitle: "Log some energy check-ins and your stats will appear here."
                )
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        overviewRow
                        distributionCard
                        factorsCard
                        weeklyCard
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Stats")
    }

    private var overviewRow: some View {
        HStack(spacing: 12) {
            let overallC = EnergyEntry.color(for: Int(store.allTimeAverage.rounded()))
            StatTile(
                icon: "bolt.fill",
                label: "All-time Avg",
                value: String(format: "%.1f", store.allTimeAverage),
                color: Color(red: overallC.r, green: overallC.g, blue: overallC.b)
            )
            StatTile(
                icon: "tray.full.fill",
                label: "Total Logs",
                value: "\(store.entries.count)",
                color: .blue
            )
            StatTile(
                icon: "calendar.badge.clock",
                label: "Days Tracked",
                value: "\(store.entriesByDay.count)",
                color: .purple
            )
        }
    }

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Energy Distribution")
                .font(.headline)

            let total = store.entries.count
            let levelLabels = ["", "Exhausted", "Low", "Moderate", "High", "Peak"]
            let levelEmojis = ["", "😴", "😔", "😐", "😊", "⚡️"]

            ForEach([5, 4, 3, 2, 1], id: \.self) { lvl in
                let count = store.entries.filter { $0.level == lvl }.count
                let fraction = total > 0 ? Double(count) / Double(total) : 0.0
                let c = EnergyEntry.color(for: lvl)
                let barColor = Color(red: c.r, green: c.g, blue: c.b)

                HStack(spacing: 10) {
                    Text("\(levelEmojis[lvl]) \(levelLabels[lvl])")
                        .font(.caption)
                        .frame(width: 100, alignment: .trailing)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor)
                                .frame(width: max(4, geo.size.width * fraction))
                        }
                    }
                    .frame(height: 18)

                    Text("\(count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)

                    Text("\(Int(fraction * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var factorsCard: some View {
        let counts = topFactors()
        return Group {
            if !counts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Most Logged Factors")
                        .font(.headline)

                    ForEach(counts.prefix(6), id: \.factor) { item in
                        HStack {
                            Circle()
                                .fill(positiveFactors.contains(item.factor) ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(item.factor)
                                .font(.subheadline)
                            Spacer()
                            Text("\(item.count)×")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var weeklyCard: some View {
        let week = store.weekEntries
        return VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 Days")
                .font(.headline)

            HStack(spacing: 20) {
                VStack {
                    Text(week.isEmpty ? "—" : String(format: "%.1f", Double(week.map(\.level).reduce(0, +)) / Double(week.count)))
                        .font(.title2.bold())
                    Text("Avg Level").font(.caption).foregroundStyle(.secondary)
                }
                Divider().frame(height: 40)
                VStack {
                    Text("\(week.count)").font(.title2.bold())
                    Text("Logs").font(.caption).foregroundStyle(.secondary)
                }
                Divider().frame(height: 40)
                VStack {
                    let high = week.filter { $0.level >= 4 }.count
                    Text("\(high)").font(.title2.bold()).foregroundStyle(.green)
                    Text("High/Peak").font(.caption).foregroundStyle(.secondary)
                }
                Divider().frame(height: 40)
                VStack {
                    let low = week.filter { $0.level <= 2 }.count
                    Text("\(low)").font(.title2.bold()).foregroundStyle(.red)
                    Text("Low/Exhausted").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func topFactors() -> [(factor: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in store.entries {
            for f in entry.factors { counts[f, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.map { (factor: $0.key, count: $0.value) }
    }
}

struct StatTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
