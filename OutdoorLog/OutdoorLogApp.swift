import SwiftUI

@main
struct OutdoorLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 680, height: 560)
    }
}
