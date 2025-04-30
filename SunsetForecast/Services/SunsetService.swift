import Foundation

// MARK: – Protocol

protocol SunsetServiceProtocol {
    /// Fetch both weather (sunset/clouds/humidity) and air-quality (AOD) data
    func fetchData(
        for date: Date,
        lat: Double,
        lon: Double
    ) async throws -> ForecastResponse
}

// MARK: – Combined Response

struct ForecastResponse {
    let daily:          RawDaily
    let hourlyWeather:  RawHourlyWeather
    let hourlyAir:      RawHourlyAir
}

// MARK: – Raw Data Models

struct RawDaily: Codable {
    let time:            [String]  // "YYYY-MM-DD"
    let sunset:          [String]  // "YYYY-MM-DDThh:mm"
    let cloudcover_mean: [Double]
}

struct RawHourlyWeather: Codable {
    let time:                 [String]  // "YYYY-MM-DDThh:mm"
    let cloudcover_high:      [Double]
    let cloudcover_mid:       [Double]
    let cloudcover_low:       [Double]
    let relativehumidity_2m:  [Double]
}

struct RawHourlyAir: Codable {
    let time:                   [String]  // "YYYY-MM-DDThh:mm"
    let aerosol_optical_depth:  [Double]
}

// MARK: – Intermediate Wrappers

private struct WeatherAPIResponse: Codable {
    let daily:  RawDaily
    let hourly: RawHourlyWeather
}

private struct AirQualityAPIResponse: Codable {
    let hourly: RawHourlyAir
}

// MARK: – Errors

enum ForecastError: Error {
    case invalidURL
    case httpError(status: Int, body: String)
    case decodingError(Error)
    case networkError(Error)
}

// MARK: – Service

final class SunsetService: ObservableObject, SunsetServiceProtocol {
    func fetchData(
        for date: Date,
        lat: Double,
        lon: Double
    ) async throws -> ForecastResponse {
        // Run both calls in parallel
        async let weather = fetchWeather(lat: lat, lon: lon)
        async let air     = fetchAirQuality(lat: lat, lon: lon)
        
        do {
            let (w, a) = try await (weather, air)
            return ForecastResponse(
                daily: w.daily,
                hourlyWeather: w.hourly,
                hourlyAir: a.hourly
            )
        } catch {
            throw error
        }
    }
    
    // MARK: – Weather Endpoint
    
    private func fetchWeather(
        lat: Double,
        lon: Double
    ) async throws -> WeatherAPIResponse {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        comps?.queryItems = [
            .init(name: "latitude",      value: "\(lat)"),
            .init(name: "longitude",     value: "\(lon)"),
            .init(name: "forecast_days", value: "10"),
            .init(name: "timezone",      value: "auto"),
            .init(name: "daily",  value: "sunset,cloudcover_mean"),
            .init(name: "hourly", value:
                ["cloudcover_high",
                 "cloudcover_mid",
                 "cloudcover_low",
                 "relativehumidity_2m"
                ].joined(separator: ",")
            )
        ]
        guard let url = comps?.url else {
            print("[SunsetService] ❌ Invalid Forecast URL")
            throw ForecastError.invalidURL
        }
        print("[SunsetService] ▶️ Weather URL:", url.absoluteString)
        
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse,
               http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("[SunsetService] 🛑 Weather HTTP \(http.statusCode):", body)
                throw ForecastError.httpError(status: http.statusCode, body: body)
            }
            let decoded = try JSONDecoder().decode(
                WeatherAPIResponse.self,
                from: data
            )
            print("[SunsetService] ✅ Weather decoded")
            return decoded
        } catch let dec as DecodingError {
            print("[SunsetService] 🛑 Weather decode error:", dec)
            throw ForecastError.decodingError(dec)
        } catch {
            print("[SunsetService] 🛑 Weather network error:", error)
            throw ForecastError.networkError(error)
        }
    }
    
    // MARK: – Air-Quality Endpoint
    
    private func fetchAirQuality(
        lat: Double,
        lon: Double
    ) async throws -> AirQualityAPIResponse {
        var comps = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")
        comps?.queryItems = [
            .init(name: "latitude",      value: "\(lat)"),
            .init(name: "longitude",     value: "\(lon)"),
            // <-- only 1 day of AQ needed
            .init(name: "forecast_days", value: "1"),
            .init(name: "timezone",      value: "auto"),
            .init(name: "hourly",        value: "aerosol_optical_depth")
        ]
        guard let url = comps?.url else {
            print("[SunsetService] ❌ Invalid AQ URL")
            throw ForecastError.invalidURL
        }
        print("[SunsetService] ▶️ AQ URL:", url.absoluteString)
        
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse,
               http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("[SunsetService] 🛑 AQ HTTP \(http.statusCode):", body)
                throw ForecastError.httpError(status: http.statusCode, body: body)
            }
            let decoded = try JSONDecoder().decode(
                AirQualityAPIResponse.self,
                from: data
            )
            print("[SunsetService] ✅ AQ decoded")
            return decoded
        } catch let dec as DecodingError {
            print("[SunsetService] 🛑 AQ decode error:", dec)
            throw ForecastError.decodingError(dec)
        } catch {
            print("[SunsetService] 🛑 AQ network error:", error)
            throw ForecastError.networkError(error)
        }
    }
}
