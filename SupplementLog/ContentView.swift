import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: SupplementStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
                .tag(0)
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(1)
            ManageView()
                .tabItem { Label("My Stack", systemImage: "list.bullet.rectangle") }
                .tag(2)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Today

struct TodayView: View {
    @EnvironmentObject var store: SupplementStore

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dateLabel)
                        .font(.headline)
                    Text(store.totalCount == 0
                         ? "No supplements added"
                         : "\(store.todayCount) of \(store.totalCount) taken")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if store.currentStreak > 0 {
                    Label("\(store.currentStreak) day streak", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 10)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.18))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(store.completionToday >= 1 ? Color.green : Color.accentColor)
                        .frame(width: max(0, geo.size.width * store.completionToday), height: 8)
                        .animation(.spring(response: 0.4), value: store.completionToday)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            .padding(.bottom, 12)

            // All-done banner
            if store.totalCount > 0 && store.todayCount >= store.totalCount {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("All supplements taken for today!")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            if store.supplements.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "cross.case")
                        .font(.system(size: 46))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No supplements in your stack yet")
                        .foregroundColor(.secondary)
                    Text("Open \"My Stack\" to add your vitamins and supplements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                Spacer()
            } else {
                List(store.supplements) { supplement in
                    SupplementRowView(supplement: supplement)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

struct SupplementRowView: View {
    @EnvironmentObject var store: SupplementStore
    let supplement: Supplement

    private var taken: Bool { store.isTaken(supplement) }
    private var takenEntry: IntakeEntry? { store.entryFor(supplement) }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if taken { store.unmarkTaken(supplement) }
                else { store.markTaken(supplement) }
            } label: {
                Image(systemName: taken ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(taken ? .green : Color.secondary.opacity(0.5))
                    .animation(.easeInOut(duration: 0.15), value: taken)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(.body)
                    .strikethrough(taken, color: .secondary)
                    .foregroundColor(taken ? .secondary : .primary)
                Text(supplement.dosage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let entry = takenEntry {
                Text(timeString(from: entry.takenAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if taken { store.unmarkTaken(supplement) }
            else { store.markTaken(supplement) }
        }
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
