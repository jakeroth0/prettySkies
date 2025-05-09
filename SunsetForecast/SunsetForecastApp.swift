import SwiftUI

@main
struct SunsetForecastApp: App {
    @StateObject private var favStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(favStore)
                .preferredColorScheme(.dark) // Force dark mode for better aesthetics
                .accentColor(.white)
        }
    }
}
