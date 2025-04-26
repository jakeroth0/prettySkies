import Foundation
import Combine                      // ← ADD THIS

protocol SunsetServiceProtocol {
    func fetchSunset(for date: Date,
                     lat: Double,
                     lon: Double) async throws -> SunsetResponse
}

struct SunsetResponse: Codable {
    let daily: [Sunset]
}

struct Sunset: Codable {
    let time: String
    let sunset: String
}

enum SunsetError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
}

final class SunsetService: ObservableObject, SunsetServiceProtocol {
    func fetchSunset(for date: Date,
                     lat: Double,
                     lon: Double) async throws -> SunsetResponse {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&daily=sunset&timezone=auto"
        guard let url = URL(string: urlString) else {
            throw SunsetError.invalidURL
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(SunsetResponse.self, from: data)
        } catch {
            throw SunsetError.networkError(error)
        }
    }
}

// Mock service for previews
final class MockSunsetService: ObservableObject, SunsetServiceProtocol {
    func fetchSunset(for date: Date,
                     lat: Double,
                     lon: Double) async throws -> SunsetResponse {
        return SunsetResponse(daily: [
            Sunset(time: "2024-03-20", sunset: "19:48:00")
        ])
    }
}
