import Foundation

struct AirQualityResponse: Codable {
    let hourly: RawHourly
    
    struct RawHourly: Codable {
        let time: [String]
        let aerosol_optical_depth_340nm: [Double]
    }
}

final class AirQualityService {
    static let shared = AirQualityService()
    private init() {}
    
    func fetchData(
        for date: Date,
        lat: Double,
        lon: Double
    ) async throws -> AirQualityResponse {
        let url = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality?" + [
            "latitude=\(lat)",
            "longitude=\(lon)",
            "hourly=aerosol_optical_depth_340nm",
            "timezone=auto"
        ].joined(separator: "&"))!
        print("[AirQualityService] ▶️ Fetching URL:", url)
        
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse {
                print("[AirQualityService] 📶 status", http.statusCode)
            }
            let decoded = try JSONDecoder().decode(AirQualityResponse.self, from: data)
            print("[AirQualityService] ✅ Decoded hourly=\(decoded.hourly.time.count)")
            return decoded
        }
        catch let dec as DecodingError {
            print("[AirQualityService] 🛑 DecodingError:", dec)
            throw ForecastError.decodingError(dec)
        }
        catch {
            print("[AirQualityService] 🛑 NetworkError:", error)
            throw ForecastError.networkError(error)
        }
    }
} 