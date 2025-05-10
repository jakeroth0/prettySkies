// SunsetForecast/Models/DailyForecast.swift

import Foundation

/// A simple model representing a forecast for a single day with a sunset quality score
struct DailyForecast: Identifiable {
    let id: Date
    let weekday: String
    let score: Int
} 