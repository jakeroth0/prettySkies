// SunsetForecast/Models/Location.swift

import Foundation
import CoreLocation

struct Location: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?
    let timeZoneIdentifier: String

    var displayName: String {
        if let admin1 = admin1, !admin1.isEmpty {
            // If we have a state/province, show "City, State, Country"
            return "\(name), \(admin1)"
        } else if !country.isEmpty {
            // If we just have country, show "City, Country"
            return "\(name), \(country)"
        } else {
            // Fallback to just the name
            return name
        }
    }

    var timeZone: TimeZone? {
        TimeZone(identifier: timeZoneIdentifier)
    }
}
