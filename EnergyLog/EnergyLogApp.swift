import SwiftUI

@main
struct EnergyLogApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 720, minHeight: 500)
        }
        .defaultSize(width: 920, height: 640)
    }
}
