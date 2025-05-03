// SunsetForecast/Services/SunsetService.swift

import Foundation

enum ForecastError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

final class SunsetService {
    static let shared = SunsetService()
    private init() {}

    /// Fetches 10-day daily+hourly data from Open-Meteo, hourly now only `cloudcover`.
    func fetchData(
        for date: Date,
        lat: Double,
        lon: Double
    ) async throws -> ForecastResponse {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?" + [
            "latitude=\(lat)",
            "longitude=\(lon)",
            "forecast_days=10",
            "timezone=auto",
            "daily=sunset,cloudcover_mean",
            "hourly=cloudcover_high,cloudcover_mid,cloudcover_low,cloudcover,relativehumidity_2m"
        ].joined(separator: "&"))!
        print("[SunsetService] ▶️ Fetching URL:", url)

        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse {
                print("[SunsetService] 📶 status", http.statusCode)
            }
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            print("[SunsetService] ✅ Decoded daily=\(decoded.daily.time.count), hourly=\(decoded.hourly.time.count)")
            return decoded
        }
        catch let dec as DecodingError {
            print("[SunsetService] 🛑 DecodingError:", dec)
            throw ForecastError.decodingError(dec)
        }
        catch {
            print("[SunsetService] 🛑 NetworkError:", error)
            throw ForecastError.networkError(error)
        }
    }
}
