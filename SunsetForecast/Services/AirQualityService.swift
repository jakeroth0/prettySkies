import Foundation

enum AirQualityError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noDataAvailable
}

/// Service for fetching air quality information from Open-Meteo API
class AirQualityService {
    static let shared = AirQualityService()
    private init() {}
    
    /// Fetches air quality data for a specific date and location
    /// - Parameters:
    ///   - date: The date to fetch data for
    ///   - lat: Latitude
    ///   - lon: Longitude
    /// - Returns: The parsed API response
    func fetchData(
        for date: Date,
        lat: Double,
        lon: Double
    ) async throws -> AQResponse {
        // Use a single integer for forecast_hours (120 hours = 5 days)
        // This gives us hourly data for the next 5 days which includes sunset times
        let forecastHoursCount = 120
        
        let url = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality?" + [
            "latitude=\(lat)",
            "longitude=\(lon)",
            "hourly=aerosol_optical_depth,dust,pm2_5",
            "forecast_hours=\(forecastHoursCount)",
            "timezone=auto"
        ].joined(separator: "&"))!
        
        print("[AirQualityService] ▶️ Fetching URL:", url)
        
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            let http = resp as? HTTPURLResponse
            let statusCode = http?.statusCode ?? 0
            print("[AirQualityService] 📶 status", statusCode)
            
            // Debug response
            if let responseStr = String(data: data, encoding: .utf8) {
                print("[AirQualityService] 📄 Response: \(responseStr.prefix(200))...")
            }
            
            // Check for error response
            guard statusCode >= 200 && statusCode < 300 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("[AirQualityService] 🛑 Error response: \(errorString)")
                }
                throw AirQualityError.networkError(NSError(domain: "HTTP", code: statusCode))
            }
            
            // Try to decode the response
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(AQResponse.self, from: data)
            
            // Validate the response
            guard !decoded.hourly.time.isEmpty else {
                throw AirQualityError.noDataAvailable
            }
            
            print("[AirQualityService] ✅ Decoded hourly=\(decoded.hourly.time.count)")
            return decoded
        } catch let airQualityError as AirQualityError {
            print("[AirQualityService] 🛑 AirQualityError:", airQualityError)
            throw airQualityError
        } catch let dec as DecodingError {
            print("[AirQualityService] 🛑 DecodingError:", dec)
            throw AirQualityError.decodingError(dec)
        } catch {
            print("[AirQualityService] 🛑 NetworkError:", error)
            throw AirQualityError.networkError(error)
        }
    }
    
    /// Calculates a clarity score (0-100) from air quality data
    /// - Parameters:
    ///   - aod: Aerosol optical depth value
    ///   - dust: Dust concentration in μg/m³
    ///   - pm25: PM2.5 concentration in μg/m³
    /// - Returns: A clarity score where 0=hazy and 100=clear
    func calculateClarityScore(aod: Double?, dust: Double?, pm25: Double?) -> Int {
        // If AOD is available, prefer it
        if let aod = aod {
            // Scale AOD to a 0-60 penalty using a sigmoid function
            // sigmoid((aod - 0.30) * 6)
            let sigmoidInput = (aod - 0.30) * 6
            let sigmoidValue = 1.0 / (1.0 + exp(-sigmoidInput))
            let penalty = 60.0 * sigmoidValue
            
            // Convert to a 0-100 clarity score (100 = clear, 0 = hazy)
            let rawScore = 100 - Int(penalty)
            return max(0, min(100, rawScore))
        }
        
        // If no AOD, use dust and pm25 as a proxy
        let dustValue = dust ?? 0.0
        let pm25Value = pm25 ?? 0.0
        
        // Weighted average based on your formula
        let proxy = 0.6 * pm25Value + 0.4 * dustValue  // μg/m³
        let penalty = min(proxy / 5.0, 60.0)  // Linear cap at 60
        
        let rawScore = 100 - Int(penalty)
        return max(0, min(100, rawScore))
    }
    
    /// Finds the AOD value closest to a given timestamp
    /// - Parameters:
    ///   - timestamp: Target timestamp (e.g., sunset time)
    ///   - response: AQ response data
    /// - Returns: The AOD value for that time, or nil if not available
    func findAODForTime(timestamp: String, in response: AQResponse) -> Double? {
        // Find the closest time index to our target timestamp
        guard let timeIndex = findClosestTimeIndex(timestamp: timestamp, times: response.hourly.time) else {
            return nil
        }
        
        // Access AOD at that index, if available
        if timeIndex < response.hourly.aerosol_optical_depth.count {
            return response.hourly.aerosol_optical_depth[timeIndex]
        }
        
        return nil
    }
    
    /// Finds dust and PM2.5 values closest to a given timestamp
    /// - Parameters:
    ///   - timestamp: Target timestamp (e.g., sunset time)
    ///   - response: AQ response data
    /// - Returns: Tuple containing (dust, pm2.5) values or nil if unavailable
    func findFallbackValues(timestamp: String, in response: AQResponse) -> (dust: Double?, pm25: Double?) {
        // Find the closest time index to our target timestamp
        guard let timeIndex = findClosestTimeIndex(timestamp: timestamp, times: response.hourly.time) else {
            return (nil, nil)
        }
        
        // Get dust value
        var dustValue: Double? = nil
        if let dustArray = response.hourly.dust, timeIndex < dustArray.count {
            dustValue = dustArray[timeIndex]
        }
        
        // Get pm2.5 value
        var pm25Value: Double? = nil
        if let pm25Array = response.hourly.pm2_5, timeIndex < pm25Array.count {
            pm25Value = pm25Array[timeIndex]
        }
        
        return (dustValue, pm25Value)
    }
    
    /// Finds the index of the closest time in a list of timestamps
    private func findClosestTimeIndex(timestamp: String, times: [String]) -> Int? {
        guard !times.isEmpty else { return nil }
        
        // Extract date components from the timestamp (expected format: "2023-04-15T18:30")
        let parts = timestamp.split(separator: "T")
        guard parts.count == 2 else { return nil }
        
        // Get just the date part for exact matching
        let datePart = String(parts[0])
        let hourPart = String(parts[1].split(separator: ":")[0])
        
        // Look for exact hour match first
        let exactLookup = "\(datePart)T\(hourPart):"
        if let exactIndex = times.firstIndex(where: { $0.hasPrefix(exactLookup) }) {
            return exactIndex
        }
        
        // If no exact match, find the closest time on the same day
        let sameDay = times.enumerated().filter { $0.element.hasPrefix(datePart) }
        if sameDay.isEmpty {
            // If no times on the target day, return the first time
            return 0
        }
        
        return sameDay.first?.offset ?? 0
    }
} 