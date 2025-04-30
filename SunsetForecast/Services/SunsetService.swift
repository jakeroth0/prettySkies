import Foundation
import Combine

protocol SunsetServiceProtocol {
    func fetchData(for date: Date,
                   lat: Double,
                   lon: Double) async throws -> ForecastResponse
}

struct ForecastResponse: Codable {
    let daily: RawDaily
    let hourly: RawHourly
}

struct RawDaily: Codable {
    let time:              [String]  // "YYYY-MM-DD"
    let sunset:            [String]  // "YYYY-MM-DDThh:mm"
    let cloudcover_mean:   [Double]
}

struct RawHourly: Codable {
    let time:               [String]  // "YYYY-MM-DDThh:mm"
    let cloudcover_high:    [Double]
    let cloudcover_mid:     [Double]
    let cloudcover_low:     [Double]
}

enum ForecastError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

final class SunsetService: ObservableObject, SunsetServiceProtocol {
    func fetchData(for date: Date,
                   lat: Double,
                   lon: Double) async throws -> ForecastResponse {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        comps?.queryItems = [
            .init(name: "latitude",          value: "\(lat)"),
            .init(name: "longitude",         value: "\(lon)"),
            .init(name: "forecast_days",     value: "10"),
            .init(name: "timezone",          value: "auto"),
            .init(name: "daily",             value: "sunset,cloudcover_mean"),
            .init(name: "hourly",            value: "cloudcover_high,cloudcover_mid,cloudcover_low")
        ]
        guard let url = comps?.url else {
            print("[SunsetService] ❌ invalid URL components")
            throw ForecastError.invalidURL
        }
        print("[SunsetService] ▶️ Fetching URL:", url.absoluteString)

        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse {
                print("[SunsetService] 📶 HTTP status:", http.statusCode)
            }
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            print("[SunsetService] ✅ Decoded daily=\(decoded.daily.time.count) items, hourly=\(decoded.hourly.time.count) items")
            return decoded

        } catch let decErr as DecodingError {
            print("[SunsetService] 🛑 DecodingError:", decErr)
            throw ForecastError.decodingError(decErr)
        } catch {
            print("[SunsetService] 🛑 NetworkError:", error)
            throw ForecastError.networkError(error)
        }
    }
}

// MARK: – Mock for Previews

final class MockSunsetService: ObservableObject, SunsetServiceProtocol {
    func fetchData(for date: Date,
                   lat: Double,
                   lon: Double) async throws -> ForecastResponse {
        let isoFmt = ISO8601DateFormatter()
        let calendar = Calendar.current

        // Build 10-day Daily arrays
        let dailyDates: [String] = (0..<10).compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: offset, to: date) else { return nil }
            return String(isoFmt.string(from: d).split(separator: "T")[0])
        }
        let dailySunsets: [String] = dailyDates.map { day in
            let minute = 30 + Int.random(in: 0..<30)
            return "\(day)T\(String(format: "%02d", minute))"
        }
        let dailyMean: [Double] = (0..<10).map { _ in Double.random(in: 0...100) }

        // Build 240-hour arrays (10 days × 24 h)
        var hourlyTimes: [String] = []
        var highs:       [Double] = []
        var mids:        [Double] = []
        var lows:        [Double] = []
        for day in dailyDates {
            for hr in 0..<24 {
                let hrString = String(format: "%02d", hr)
                let timestamp = "\(day)T\(hrString):00"
                hourlyTimes.append(timestamp)
                highs.append(Double.random(in: 0...100))
                mids.append(Double.random(in: 0...100))
                lows.append(Double.random(in: 0...100))
            }
        }

        let daily = RawDaily(
            time:            dailyDates,
            sunset:          dailySunsets,
            cloudcover_mean: dailyMean
        )
        let hourly = RawHourly(
            time:              hourlyTimes,
            cloudcover_high:   highs,
            cloudcover_mid:    mids,
            cloudcover_low:    lows
        )
        print("[MockSunsetService] 🧪 Generated \(dailyDates.count) daily & \(hourlyTimes.count) hourly entries")
        return ForecastResponse(daily: daily, hourly: hourly)
    }
}
