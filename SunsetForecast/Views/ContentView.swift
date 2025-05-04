// SunsetForecast/Views/ContentView.swift

import SwiftUI
import CoreLocation

// Simple model for each day's score
struct DailyForecast: Identifiable {
    let id:      Date
    let weekday: String
    let score:   Int
}

struct ContentView: View {
    // MARK: – State & Services

    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var favoritesStore: FavoritesStore
    private let sunsetService = SunsetService.shared

    @State private var locationName: String?
    @State private var forecasts:    [DailyForecast] = []

    // Today's detailed values
    @State private var todayCloudMean: Double?
    @State private var todayCloudAtSun: Double?
    @State private var todayAod: Double?
    @State private var todayHumidity: Double?
    @State private var sunsetMoment: Date?
    @State private var goldenMoment: Date?

    @State private var isLoading     = false
    @State private var errorMessage: String?
    @State private var lastCoord: CLLocationCoordinate2D?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Details View
            ZStack {
                // Always show the background gradient
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

                // Conditionally show content or loading spinner
                if let coord = locationManager.coordinate, coord.latitude != 0.0, coord.longitude != 0.0 {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerView
                            todayScoreView
                            variableCardView
                            forecastCardView
                        }
                        .padding()
                    }
                } else {
                    ProgressView("Waiting for location...")
                        .scaleEffect(1.5)
                        .tint(.white)
                }

                // loading & error overlays
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                if let err = errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                }
            }
            .onAppear { locationManager.requestLocation() }
            .onReceive(locationManager.$coordinate) { coordOpt in
                guard let coord = coordOpt,
                      coord.latitude != 0.0, coord.longitude != 0.0,
                      coord.latitude != lastCoord?.latitude ||
                      coord.longitude != lastCoord?.longitude
                else { return }

                lastCoord = coord
                Task {
                    await fetchLocationName(coord)
                    await loadData(for: coord)
                }
            }
            .tabItem {
                Label("Details", systemImage: "sun.max.fill")
            }
            .tag(0)
            
            // Favorites View
            FavoritesView()
                .tabItem {
                    Label("Locations", systemImage: "list.bullet")
                }
                .tag(1)
        }
    }

    // MARK: – Header

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("My Location")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            if let name = locationName {
                Text(name)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: – Today's Score & Times

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

    // MARK: – Today's Conditions Grid

    private var variableCardView: some View {
        VStack(spacing: 12) {
            Text("Today's Conditions")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(), GridItem()]) {
                // Cloud Mean
                if let cm = todayCloudMean {
                    variableTile(icon: "cloud.fill",
                                 title: "Clouds (mean)",
                                 label: labelCloudMean(cm))
                } else {
                    variableTile(icon: "cloud.fill",
                                 title: "Clouds (mean)",
                                 label: "Loading...")
                }
                
                // Cloud at Sunset
                if let cu = todayCloudAtSun {
                    variableTile(icon: "cloud.sun.fill",
                                 title: "Cloud @ Sun",
                                 label: "\(Int(cu))%")
                } else {
                    variableTile(icon: "cloud.sun.fill",
                                 title: "Cloud @ Sun",
                                 label: "Loading...")
                }
                
                // Humidity
                if let hu = todayHumidity {
                    variableTile(icon: "humidity.fill",
                                 title: "Humidity",
                                 label: labelHumidity(hu))
                } else {
                    variableTile(icon: "humidity.fill",
                                 title: "Humidity",
                                 label: "Loading...")
                }
                
                // AOD
                if let ao = todayAod {
                    variableTile(icon: "sun.haze.fill",
                                 title: "AOD",
                                 label: labelAOD(ao))
                } else {
                    variableTile(icon: "sun.haze.fill",
                                 title: "AOD",
                                 label: "Loading...")
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func variableTile(icon: String,
                              title: String,
                              label: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }

    // MARK: – 10-Day Forecast Card

    private var forecastCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("10-Day Forecast", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(.white)
            ForEach(forecasts) { d in
                HStack(spacing: 12) {
                    Text(d.weekday)
                        .frame(width: 40, alignment: .leading)
                        .foregroundColor(.white)
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.white)
                    GeometryReader { geo in
                        let frac = CGFloat(d.score) / 100
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width * frac,
                                       height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("\(d.score)%")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.white)
                }
                .frame(height: 28)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: – Networking & Data

    private func fetchLocationName(_ coord: CLLocationCoordinate2D) async {
        let loc = CLLocation(latitude: coord.latitude,
                             longitude: coord.longitude)
        if let p = try? await CLGeocoder().reverseGeocodeLocation(loc).first {
            let parts = [p.locality, p.administrativeArea, p.country]
                .compactMap { $0 }
            let name = parts.joined(separator: ", ")
            await MainActor.run {
                locationName = name
                print("[Location] set to", name)
            }
        }
    }

    private func loadData(for coord: CLLocationCoordinate2D) async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }

        do {
            // 1️⃣ weather + cloudcover
            let resp = try await sunsetService.fetchData(
                for: Date(),
                lat: coord.latitude,
                lon: coord.longitude
            )
            print("[Data] got daily=\(resp.daily.time.count), hourly=\(resp.hourly.time.count)")

            // build forecast list
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

            // today's times & mean
            let sunFmt = DateFormatter()
            sunFmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
            if let sunD = sunFmt.date(from: resp.daily.sunset[0]) {
                sunsetMoment = sunD
                goldenMoment = sunD.addingTimeInterval(-1800)
            }
            todayCloudMean = resp.daily.cloudcover_mean[0]

            // 2️⃣ Air Quality - now with proper forecast_hours
            var aodValue: Double? = nil
            var dustValue: Double? = nil
            var pm25Value: Double? = nil
            
            do {
                let aqResp = try await AirQualityService.shared.fetchData(
                    for: Date(), 
                    lat: coord.latitude, 
                    lon: coord.longitude
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

            // commit
            await MainActor.run {
                forecasts    = list
                errorMessage = nil
                print("[Data] built \(list.count) days")
            }
        }
        catch {
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

    // MARK: – Labels

    private func labelCloudMean(_ v: Double) -> String {
        v < 20   ? "Clear" :
        v < 60   ? "Partly" :
                  "Overcast"
    }

    private func labelHumidity(_ v: Double) -> String {
        v < 40  ? "Dry" :
        v < 70  ? "OK" :
                  "Humid"
    }

    private func labelAOD(_ v: Double) -> String {
        v < 0.1  ? "Low" :
        v < 0.3  ? "Mod" :
                  "High"
    }
}

