import SwiftUI

@main
struct SupplementLogApp: App {
    @StateObject private var store = SupplementStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 520, minHeight: 600)
        }
        .windowResizability(.contentMinSize)
    }
}
