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
        if let admin1 = admin1 {
            return "\(name), \(admin1), \(country)"
        }
        return "\(name), \(country)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var timeZone: TimeZone? {
        TimeZone(identifier: timeZoneIdentifier)
    }
}
