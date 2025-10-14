import SwiftUI
import SwiftData

@main
struct AndOneApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(.andOrange)  
        }
        .modelContainer(for: [Court.self, Player.self, Game.self])
    }
}
