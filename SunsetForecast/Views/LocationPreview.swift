import SwiftUI
import CoreLocation

struct LocationPreview: View {
    // MARK: - Properties
    
    let location: Location
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var favoritesStore: FavoritesStore
    
    @State private var forecasts: [DailyForecast] = []
    @State private var todayCloudMean: Double?
    @State private var todayCloudAtSun: Double?
    @State private var todayAod: Double?
    @State private var todayHumidity: Double?
    @State private var sunsetMoment: Date?
    @State private var goldenMoment: Date?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let sunsetService = SunsetService.shared
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            // Background gradient - using sunset colors
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#FF6B5C"),
                    Color(hex: "#FFB35C"),
                    Color(hex: "#FFD56B")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Location header
                    VStack(spacing: 4) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        Text(location.displayName)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    
                    // Today's Score
                    todayScoreView
                    
                    // Today's Conditions
                    TodayConditionsCard(
                        cloudMean: todayCloudMean,
                        cloudAtSun: todayCloudAtSun,
                        humidity: todayHumidity,
                        aod: todayAod
                    )
                    
                    // 10-day Forecast
                    ForecastCard(forecasts: forecasts)
                }
                .padding()
            }
            
            // Loading overlay
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            
            // Error message
            if let err = errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Cancel button
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            
            // Add button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    favoritesStore.add(location)
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Score View
    
    private var todayScoreView: some View {
        VStack(spacing: 8) {
            if let score = forecasts.first?.score {
                Text("\(score)%")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundColor(.white)
                HStack(spacing: 16) {
                    if let g = goldenMoment {
                        Text("Golden \(g.formatted(.dateTime.hour().minute()))")
                    }
                    if let s = sunsetMoment {
                        Text("Sunset \(s.formatted(.dateTime.hour().minute()))")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        do {
            // Fetch weather data
            let resp = try await sunsetService.fetchData(
                for: Date(),
                lat: location.latitude,
                lon: location.longitude
            )
            
            // Build forecast list
            let dayFmt = DateFormatter()
            dayFmt.dateFormat = "yyyy-MM-dd"
            var list: [DailyForecast] = []
            
            for i in resp.daily.time.indices {
                guard let d = dayFmt.date(from: resp.daily.time[i]) else { continue }
                let wd = d.formatted(.dateTime.weekday(.abbreviated))
                let sc: Int
                if i == 0, let idx = indexFor(resp.daily.sunset[i], in: resp.hourly.time) {
                    // Get cloud cover at different heights
                    let hi = resp.hourly.cloudcover_high[idx]
                    let mi = resp.hourly.cloudcover_mid[idx]
                    let lo = resp.hourly.cloudcover_low[idx]
                    let totalCloud = resp.hourly.cloudcover[idx]
                    
                    // Apply weighted formula - reward high clouds, neutral for mid, penalize low clouds
                    let weightedCloud = (0.4 * hi) + (0.0 * mi) - (0.3 * lo)
                    
                    // Scale to 0-100 range, where higher is better cloud conditions for sunset
                    sc = 50 + Int(weightedCloud.clamped(to: -50...50))
                    
                    todayCloudAtSun = totalCloud
                    todayHumidity = resp.hourly.relativehumidity_2m[idx]
                } else {
                    // For future days, use cloudcover_mean but invert (higher score = better)
                    sc = max(0, 100 - Int(resp.daily.cloudcover_mean[i]))
                }
                list.append(DailyForecast(id: d, weekday: wd, score: sc))
            }
            
            // Today's times & mean
            let sunFmt = DateFormatter()
            sunFmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
            if let sunD = sunFmt.date(from: resp.daily.sunset[0]) {
                sunsetMoment = sunD
                goldenMoment = sunD.addingTimeInterval(-1800)
            }
            todayCloudMean = resp.daily.cloudcover_mean[0]
            
            // Air Quality
            var aodValue: Double? = nil
            var dustValue: Double? = nil
            var pm25Value: Double? = nil
            
            do {
                let aqResp = try await AirQualityService.shared.fetchData(
                    for: Date(),
                    lat: location.latitude,
                    lon: location.longitude
                )
                
                if let sunsetTime = resp.daily.sunset.first {
                    // Try to get AOD value at sunset time
                    aodValue = AirQualityService.shared.findAODForTime(
                        timestamp: sunsetTime,
                        in: aqResp
                    )
                    
                    // Get fallback values if needed
                    let fallback = AirQualityService.shared.findFallbackValues(
                        timestamp: sunsetTime,
                        in: aqResp
                    )
                    dustValue = fallback.dust
                    pm25Value = fallback.pm25
                    
                    print("[Data] AOD=\(String(describing: aodValue)), dust=\(String(describing: dustValue)), pm25=\(String(describing: pm25Value))")
                }
            } catch {
                print("[Data] Air quality error:", error)
                // Continue without air quality data
            }
            
            // Calculate final score with air quality
            if let idx = list.indices.first, let firstDay = list.first {
                // Apply clarity adjustment from air quality data
                let clarityScore = AirQualityService.shared.calculateClarityScore(
                    aod: aodValue,
                    dust: dustValue,
                    pm25: pm25Value
                )
                
                // Blend cloud and clarity scores (70% clouds, 30% clarity)
                let finalScore = Int(0.7 * Double(firstDay.score) + 0.3 * Double(clarityScore))
                let clampedScore = max(0, min(100, finalScore))
                
                // Update first day with adjusted score
                list[idx] = DailyForecast(
                    id: firstDay.id,
                    weekday: firstDay.weekday,
                    score: clampedScore
                )
                
                print("[Data] Cloud score=\(firstDay.score), clarity=\(clarityScore), final=\(clampedScore)")
            }
            
            // Store AOD value
            todayAod = aodValue
            
            // Commit
            await MainActor.run {
                forecasts = list
                errorMessage = nil
                print("[Data] built \(list.count) days")
            }
        } catch {
            print("[Data] error:", error)
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
    
    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let parts = isoSun.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let lookup = "\(parts[0])T\(parts[1].split(separator: ":")[0]):"
        return hours.firstIndex { $0.hasPrefix(lookup) }
    }
}

#Preview {
    NavigationStack {
        LocationPreview(
            location: Location(
                id: "preview-location",
                name: "San Francisco",
                latitude: 37.7749,
                longitude: -122.4194,
                country: "US",
                admin1: "California",
                timeZoneIdentifier: "America/Los_Angeles"
            )
        )
        .environmentObject(FavoritesStore())
    }
} 