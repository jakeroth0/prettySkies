// SunsetForecast/Services/OpenMeteoSearchService.swift

import Foundation

/// Uses Open-Meteo’s free geocoding endpoint
struct OpenMeteoSearchService: LocationSearchService {
    func search(_ query: String) async throws -> [Location] {
        guard
          let encoded = query.addingPercentEncoding(
                            withAllowedCharacters: .urlQueryAllowed
                        ),
          var comps = URLComponents(
                            string: "https://geocoding-api.open-meteo.com/v1/search"
                        )
        else {
            throw SearchError.invalidURL
        }

        comps.queryItems = [
          .init(name: "name",     value: encoded),
          .init(name: "count",    value: "5"),
          .init(name: "language", value: "en"),
          .init(name: "format",   value: "json")
        ]

        guard let url = comps.url else {
            throw SearchError.invalidURL
        }
        print("[Search] ▶️ \(url)")
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let wrapper = try JSONDecoder().decode(OMResponse.self, from: data)
            return wrapper.results?
              .map { res in
                // Compose a user-friendly name
                let parts = [res.name,
                             res.admin1,
                             res.country]
                             .compactMap{ $0 }
                let title = parts.joined(separator: ", ")
                return Location(
                  name: title,
                  latitude: res.latitude,
                  longitude: res.longitude
                )
              } ?? []
        } catch let dec as DecodingError {
            print("[Search] 🛑 decode:", dec)
            throw SearchError.decodingError(dec)
        } catch {
            print("[Search] 🛑 network:", error)
            throw SearchError.networkError(error)
        }
    }

    // MARK: – Geocoding JSON

    private struct OMResponse: Codable {
        let results: [Result]?
        struct Result: Codable {
            let name:      String
            let latitude:  Double
            let longitude: Double
            let country:   String?
            let admin1:    String?

            private enum CodingKeys: String, CodingKey {
                case name, latitude, longitude, country
                case admin1 = "admin1"
            }
        }
    }
}
