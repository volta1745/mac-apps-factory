import SwiftUI

@main
struct MeditationLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 780, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
