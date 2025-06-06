import Foundation

/// Uses Open-Meteo geocoding API to lookup up to 10 places.
struct OpenMeteoSearchService: LocationSearchService {
    func search(_ query: String) async throws -> [Location] {
        let base = "https://geocoding-api.open-meteo.com/v1/search"
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "\(base)?name=\(q)&count=10&language=en&format=json"
        guard let url = URL(string: urlStr) else {
            throw URLError(.badURL)
        }
        print("[GeoSearch] ▶️", url)
        let (data, resp) = try await URLSession.shared.data(from: url)
        if let http = resp as? HTTPURLResponse {
            print("[GeoSearch] status", http.statusCode)
        }
        // Debug: Print raw JSON
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[GeoSearch] Raw JSON: \(jsonString)")
        }
        struct R: Codable { let results: [Result] }
        struct Result: Codable {
            let name: String, latitude: Double, longitude: Double
            let country: String?, admin1: String?
            let admin2: String?, admin3: String?, admin4: String?
            let timezone: String?
        }
        let container = try JSONDecoder().decode(R.self, from: data)
        print("[GeoSearch] Decoded results count: \(container.results.count)")
        
        return container.results.map { r in
            Location(
                id: "\(r.latitude),\(r.longitude)",
                name: r.name,
                latitude: r.latitude,
                longitude: r.longitude,
                country: r.country ?? "",
                admin1: r.admin1,
                timeZoneIdentifier: r.timezone ?? TimeZone.current.identifier
            )
        }
    }
}
