// SunsetForecast/Models/AQResponse.swift

import Foundation

/// The data coming back from the air-quality endpoint.
struct AQResponse: Codable {
    let hourly: HourlyAQ

    struct HourlyAQ: Codable {
        /// Aerosol Optical Depth hourly for the next day
        let aerosol_optical_depth: [Double]
    }
}
