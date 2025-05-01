// SunsetForecast/Models/Location.swift

import Foundation

struct Location: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double

    init(
        id: UUID = .init(),
        name: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
