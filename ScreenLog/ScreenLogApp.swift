import SwiftUI

@main
struct ScreenLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SessionStore.shared)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 760, height: 560)
    }
}
