import Foundation
import CoreLocation

/// A searchable or favorite location.
struct Location: Identifiable, Codable, Hashable {
    let id: String               // e.g. "lat,lon"
    let name: String             // city
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?          // state / region
    let timeZoneIdentifier: String

    var displayName: String {
        if let a1 = admin1 { return "\(name), \(a1)" }
        return name
    }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var timeZone: TimeZone? {
        TimeZone(identifier: timeZoneIdentifier)
    }
}
