import SwiftUI
import SwiftData

@main
struct AndOneApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(.andOrange)          // Accent
        }
        .modelContainer(for: [Court.self, Player.self, Game.self])
    }
}
