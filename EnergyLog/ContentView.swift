import SwiftUI

enum NavItem: Hashable {
    case log, today, history, stats
}

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selection: NavItem? = .log

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $selection) {
                Section("Track") {
                    Label("Log Energy", systemImage: "bolt.fill")
                        .tag(NavItem.log)
                    Label("Today", systemImage: "sun.max.fill")
                        .tag(NavItem.today)
                }
                Section("Review") {
                    Label("History", systemImage: "clock.fill")
                        .tag(NavItem.history)
                    Label("Stats", systemImage: "chart.bar.fill")
                        .tag(NavItem.stats)
                }
            }
            .navigationTitle("EnergyLog")
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selection ?? .log {
            case .log:
                LogEnergyView()
            case .today:
                TodayView()
            case .history:
                HistoryView()
            case .stats:
                StatsView()
            }
        }
    }
}
