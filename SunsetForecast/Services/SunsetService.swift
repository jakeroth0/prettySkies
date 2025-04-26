import Foundation

struct SunsetResponse: Codable {
    let daily: Daily
}

struct Daily: Codable {
    let time: [String]
    let sunset: [String]
}

enum SunsetError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
}

struct SunsetService {
    static func fetchSunset(for date: Date, lat: Double, lon: Double) async throws -> Date {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&daily=sunset&timezone=auto"
        guard let url = URL(string: urlString) else {
            throw SunsetError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SunsetResponse.self, from: data)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        guard let sunsetTime = response.daily.sunset.first,
              let sunsetDate = dateFormatter.date(from: sunsetTime) else {
            throw SunsetError.invalidResponse
        }
        
        return sunsetDate
    }
}

// Mock service for previews
struct MockSunsetService {
    static func fetchSunset(for date: Date, lat: Double, lon: Double) async throws -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 19
        components.minute = 48
        return calendar.date(from: components)!
    }
} 