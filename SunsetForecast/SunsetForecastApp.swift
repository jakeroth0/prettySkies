import SwiftUI

@main
struct SunsetForecastApp: App {
    @StateObject private var favStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
              .environmentObject(favStore)
        }
    }
}
