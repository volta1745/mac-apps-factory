import SwiftUI

@main
struct SocialLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Interaction…") {
                    NotificationCenter.default.post(name: .newInteraction, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .defaultSize(width: 800, height: 560)
    }
}

extension Notification.Name {
    static let newInteraction = Notification.Name("SocialLog.newInteraction")
}
