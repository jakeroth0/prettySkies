import Foundation

protocol SunsetServiceProtocol {
    func fetchData(for date: Date,
                   lat: Double,
                   lon: Double) async throws -> ForecastResponse
}

/// Combines weather & air‐quality into one payload.
struct ForecastResponse {
    let daily: RawDaily
    let hourlyWeather: RawHourlyWeather
    let hourlyAir: RawHourlyAir
}

struct RawDaily: Codable {
    let time: [String]              // YYYY-MM-DD
    let sunset: [String]            // YYYY-MM-DDThh:mm
    let cloudcover_mean: [Double]
}

struct RawHourlyWeather: Codable {
    let time: [String]              // YYYY-MM-DDThh:mm
    let cloudcover_high: [Double]
    let cloudcover_mid: [Double]
    let cloudcover_low: [Double]
    let relativehumidity_2m: [Double]
}

struct RawHourlyAir: Codable {
    let time: [String]              // YYYY-MM-DDThh:mm
    let aerosol_optical_depth: [Double]
}

enum ForecastError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

final class SunsetService: SunsetServiceProtocol {
    static let shared = SunsetService()
    private init() {}

    func fetchData(for date: Date,
                   lat: Double,
                   lon: Double) async throws -> ForecastResponse {
        // 1) Build the weather forecast URL
        var w = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        w?.queryItems = [
            .init(name: "latitude",  value: "\(lat)"),
            .init(name: "longitude", value: "\(lon)"),
            .init(name: "forecast_days", value: "10"),
            .init(name: "timezone", value: "auto"),
            .init(name: "daily",    value: "sunset,cloudcover_mean"),
            .init(name: "hourly",   value: "cloudcover_high,cloudcover_mid,cloudcover_low,relativehumidity_2m")
        ]
        guard let weatherURL = w?.url else {
            print("[SunsetService] ❌ invalid weather URL")
            throw ForecastError.invalidURL
        }
        print("[SunsetService] ▶️ Weather URL:", weatherURL)

        // 2) Build the air‐quality URL
        var a = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")
        a?.queryItems = [
            .init(name: "latitude",  value: "\(lat)"),
            .init(name: "longitude", value: "\(lon)"),
            .init(name: "forecast_days", value: "1"),
            .init(name: "timezone", value: "auto"),
            .init(name: "hourly",   value: "aerosol_optical_depth")
        ]
        guard let airURL = a?.url else {
            print("[SunsetService] ❌ invalid AQ URL")
            throw ForecastError.invalidURL
        }
        print("[SunsetService] ▶️ AQ URL:", airURL)

        // 3) Fire off both requests in parallel
        async let weatherTask = URLSession.shared.data(from: weatherURL)
        async let airTask     = URLSession.shared.data(from: airURL)

        do {
            let (wData, wResp) = try await weatherTask
            if let http = wResp as? HTTPURLResponse {
                print("[SunsetService] 📶 Weather status:", http.statusCode)
            }
            let weatherDecoded = try JSONDecoder().decode(
                WeatherWrapper.self,
                from: wData
            )

            let (aData, aResp) = try await airTask
            if let http2 = aResp as? HTTPURLResponse {
                print("[SunsetService] 📶 AQ status:", http2.statusCode)
            }
            let airDecoded = try JSONDecoder().decode(
                AQWrapper.self,
                from: aData
            )

            return ForecastResponse(
                daily: weatherDecoded.daily,
                hourlyWeather: weatherDecoded.hourly,
                hourlyAir: airDecoded.hourly
            )

        } catch let dec as DecodingError {
            print("[SunsetService] 🛑 DecodingError:", dec)
            throw ForecastError.decodingError(dec)
        } catch {
            print("[SunsetService] 🛑 NetworkError:", error)
            throw ForecastError.networkError(error)
        }
    }

    // Helpers to match the JSON payloads
    private struct WeatherWrapper: Codable {
        let daily: RawDaily
        let hourly: RawHourlyWeather
    }
    private struct AQWrapper: Codable {
        let hourly: RawHourlyAir
    }
}
