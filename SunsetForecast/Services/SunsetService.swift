// SunsetForecast/Services/SunsetService.swift

import Foundation
import Combine

protocol SunsetServiceProtocol {
    func fetchData(
      for date: Date,
      lat: Double,
      lon: Double
    ) async throws -> ForecastResponse
}

struct ForecastResponse: Codable {
    let daily: RawDaily
    let hourly: RawHourly
}

struct RawDaily: Codable {
    let time: [String]
    let sunset: [String]
    let cloudcover_mean: [Double]
}

struct RawHourly: Codable {
    let time: [String]
    let cloudcover_high: [Double]
    let cloudcover_mid: [Double]
    let cloudcover_low: [Double]
}

enum ForecastError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

final class SunsetService: ObservableObject, SunsetServiceProtocol {
    static let shared = SunsetService()

    func fetchData(
      for date: Date,
      lat: Double,
      lon: Double
    ) async throws -> ForecastResponse {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        comps?.queryItems = [
            .init(name: "latitude", value: "\(lat)"),
            .init(name: "longitude", value: "\(lon)"),
            .init(name: "forecast_days", value: "10"),
            .init(name: "timezone", value: "auto"),
            .init(name: "daily", value: "sunset,cloudcover_mean"),
            .init(name: "hourly", value: "cloudcover_high,cloudcover_mid,cloudcover_low")
        ]
        guard let url = comps?.url else {
            print("[SunsetService] ❌ invalid URL")
            throw ForecastError.invalidURL
        }
        print("[SunsetService] ▶️ Fetching URL:", url)
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse {
                print("[SunsetService] 📶 HTTP status:", http.statusCode)
            }
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            print("[SunsetService] ✅ Decoded daily=\(decoded.daily.time.count), hourly=\(decoded.hourly.time.count)")
            return decoded
        } catch let dec as DecodingError {
            print("[SunsetService] 🛑 DecodingError:", dec)
            throw ForecastError.decodingError(dec)
        } catch {
            print("[SunsetService] 🛑 NetworkError:", error)
            throw ForecastError.networkError(error)
        }
    }
}
