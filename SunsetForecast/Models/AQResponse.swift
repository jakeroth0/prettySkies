// SunsetForecast/Models/AQResponse.swift

import Foundation

/// The data coming back from the air-quality endpoint.
struct AQResponse: Codable {
    let hourly: HourlyAQ

    struct HourlyAQ: Codable {
        /// Aerosol Optical Depth at 550 nm of the entire atmosphere to indicate haze
        let aerosol_optical_depth: [Double?]
        
        /// Dust particles (μg/m³) close to surface as fallback
        let dust: [Double?]?
        
        /// PM2.5 particulate matter (μg/m³) as fallback
        let pm2_5: [Double?]?
        
        /// Timestamps for the hourly data
        let time: [String]
        
        private enum CodingKeys: String, CodingKey {
            case aerosol_optical_depth, dust, pm2_5, time
        }
    }
}
