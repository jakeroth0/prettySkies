// SunsetForecast/Models/ForecastResponse.swift

import Foundation

/// The data coming back from the main weather endpoint.
struct ForecastResponse: Codable {
    let daily: RawDaily
    let hourly: RawHourly

    struct RawDaily: Codable {
        let time: [String]
        let sunset: [String]
        let cloudcover_mean: [Double]
    }

    struct RawHourly: Codable {
        let time: [String]
        /// High-level cloud cover (0-100%)
        let cloudcover_high: [Double]
        /// Mid-level cloud cover (0-100%)
        let cloudcover_mid: [Double]
        /// Low-level cloud cover (0-100%)
        let cloudcover_low: [Double]
        /// Total cloud cover (0-100%)
        let cloudcover: [Double]
        /// Relative humidity at 2 meters (0-100%)
        let relativehumidity_2m: [Double]
    }
}
