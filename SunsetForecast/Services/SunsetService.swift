import Foundation
import Combine

protocol SunsetServiceProtocol {
    func fetchSunset(for date: Date,
                     lat: Double,
                     lon: Double) async throws -> SunsetResponse
}

struct SunsetResponse: Codable {
    let daily: RawDaily
}

struct RawDaily: Codable {
    let time: [String]
    let sunset: [String]
    let cloudcover_mean: [Double]
}

enum SunsetError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

final class SunsetService: ObservableObject, SunsetServiceProtocol {
    func fetchSunset(for date: Date,
                     lat: Double,
                     lon: Double) async throws -> SunsetResponse {
        // Build the URL
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        comps?.queryItems = [
            .init(name: "latitude", value: "\(lat)"),
            .init(name: "longitude", value: "\(lon)"),
            .init(name: "daily", value: "sunset,cloudcover_mean"),
            .init(name: "timezone", value: "auto")
        ]
        guard let url = comps?.url else {
            print("[SunsetService] ERROR: invalid URL components")
            throw SunsetError.invalidURL
        }
        print("[SunsetService] Fetching URL:", url.absoluteString)

        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse {
                print("[SunsetService] HTTP status:", http.statusCode)
            }
            if let json = String(data: data, encoding: .utf8) {
                print("[SunsetService] Raw JSON response:", json)
            }
            let decoded = try JSONDecoder().decode(SunsetResponse.self, from: data)
            print("[SunsetService] Decoded daily counts — time:", decoded.daily.time.count,
                  "sunset:", decoded.daily.sunset.count,
                  "cloudcover:", decoded.daily.cloudcover_mean.count)
            return decoded

        } catch let decErr as DecodingError {
            print("[SunsetService] DecodingError:", decErr)
            throw SunsetError.decodingError(decErr)

        } catch {
            print("[SunsetService] NetworkError:", error)
            throw SunsetError.networkError(error)
        }
    }
}

// Mock service for previews / testing
final class MockSunsetService: ObservableObject, SunsetServiceProtocol {
    func fetchSunset(for date: Date,
                     lat: Double,
                     lon: Double) async throws -> SunsetResponse {
        let stub = RawDaily(
            time: ["2025-04-26"],
            sunset: ["19:55"],
            cloudcover_mean: [70.0]
        )
        print("[MockSunsetService] returning stub data:", stub)
        return SunsetResponse(daily: stub)
    }
}
