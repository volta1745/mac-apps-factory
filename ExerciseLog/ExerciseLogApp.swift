import SwiftUI

@main
struct ExerciseLogApp: App {
    @StateObject private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environmentObject(store)
            }
        }
        .defaultSize(width: 700, height: 560)
    }
}
