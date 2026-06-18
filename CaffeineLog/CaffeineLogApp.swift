import SwiftUI

@main
struct CaffeineLogApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 500, minHeight: 400)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Log a Drink…") {
                    // Handled via toolbar; listed here for discoverability
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(true)
            }
        }
    }
}
