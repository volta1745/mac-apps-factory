import SwiftUI

struct ContentView: View {
    @StateObject private var store = SessionStore()
    @State private var selection: Panel? = .log

    enum Panel: Hashable {
        case log, history, stats
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Log Session", systemImage: "plus.circle.fill")
                    .tag(Panel.log)
                Label("History", systemImage: "clock.fill")
                    .tag(Panel.history)
                Label("Stats", systemImage: "chart.bar.fill")
                    .tag(Panel.stats)
            }
            .navigationTitle("CreativeLog")
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            switch selection ?? .log {
            case .log:
                LogSessionView(store: store)
            case .history:
                HistoryView(store: store)
            case .stats:
                StatsView(store: store)
            }
        }
    }
}
