// SunsetForecast/SunsetForecastApp.swift
import SwiftUI

@main
struct SunsetForecastApp: App {
    @StateObject private var favoritesStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favoritesStore)
        }
    }
}
