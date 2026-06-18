import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddDrink = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(showAddDrink: $showAddDrink)
                .tabItem { Label("Today", systemImage: "cup.and.saucer.fill") }
                .tag(0)

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(1)
        }
        .sheet(isPresented: $showAddDrink) {
            AddDrinkView().environmentObject(store)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddDrink = true
                } label: {
                    Label("Add Drink", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct TodayView: View {
    @EnvironmentObject var store: DataStore
    @Binding var showAddDrink: Bool

    private var caffeineColor: Color {
        let mg = store.todayTotalMg
        if mg < 200 { return .green }
        if mg < 400 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 0) {
            // Daily summary banner
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Caffeine")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(store.todayTotalMg)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(caffeineColor)
                        Text("mg")
                            .font(.title3).foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Drinks")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(store.todayEntries.count)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                }

                Divider().frame(height: 50)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily Limit")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("400 mg")
                        .font(.title2).bold().foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.secondary.opacity(0.15))
                    Rectangle()
                        .fill(caffeineColor)
                        .frame(width: geo.size.width * min(Double(store.todayTotalMg) / 400.0, 1.0))
                        .animation(.easeInOut, value: store.todayTotalMg)
                }
            }
            .frame(height: 6)

            Divider()

            if store.todayEntries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.todayEntries) { entry in
                        DrinkRow(entry: entry)
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets, in: store.todayEntries)
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No drinks logged today")
                .font(.title3).foregroundStyle(.secondary)
            Button("Log Your First Drink") { showAddDrink = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoryView: View {
    @EnvironmentObject var store: DataStore

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        if store.distinctDays.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 48)).foregroundStyle(.secondary)
                Text("No history yet").font(.title3).foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                ForEach(store.distinctDays, id: \.self) { day in
                    let dayEntries = store.entries(for: day)
                    let total = dayEntries.reduce(0) { $0 + $1.caffeineMg }
                    Section {
                        ForEach(dayEntries) { entry in
                            DrinkRow(entry: entry)
                        }
                    } header: {
                        HStack {
                            Text(dayFormatter.string(from: day))
                                .font(.headline)
                            Spacer()
                            Text("\(total) mg total")
                                .font(.subheadline)
                                .foregroundStyle(total > 400 ? .red : .secondary)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }
}

struct DrinkRow: View {
    let entry: DrinkEntry

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.drinkType.icon)
                .font(.title2)
                .foregroundStyle(.brown)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.body).bold()
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.caffeineMg) mg")
                    .font(.body.monospacedDigit()).bold()
                    .foregroundStyle(.secondary)
                Text(timeFormatter.string(from: entry.timestamp))
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
