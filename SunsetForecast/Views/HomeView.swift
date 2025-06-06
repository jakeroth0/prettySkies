// SunsetForecast/Views/HomeView.swift

import SwiftUI
import CoreLocation

// Add necessary imports for components and models

struct HomeView: View {
    // MARK: - State & Services
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var favoritesStore: FavoritesStore
    private let sunsetService = SunsetService.shared

    @State private var locationName: String?
    @State private var forecasts: [DailyForecast] = []

    // Today's detailed values
    @State private var todayCloudMean: Double?
    @State private var todayCloudAtSun: Double?
    @State private var todayAod: Double?
    @State private var todayHumidity: Double?
    @State private var sunsetMoment: Date?
    @State private var goldenMoment: Date?

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastCoord: CLLocationCoordinate2D?
    @ObservedObject private var tabSelection = TabViewSelection.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content based on selected tab
            Group {
                if tabSelection.selectedTab == .home {
                    // Home / Details View
                    ZStack {
                        // Background gradient
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("#FF6B5C"),
                                Color("#FFB35C"),
                                Color("#FFD56B")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()

                        // Conditionally show content or loading spinner
                        if let coord = locationManager.coordinate, coord.latitude != 0.0, coord.longitude != 0.0 {
                            // TabView for swiping between location pages
                            TabView(selection: $tabSelection.homePageIndex) {
                                // Current location page
                                ScrollView {
                                    VStack(spacing: 24) {
                                        headerView
                                        todayScoreView
                                        
                                        // Today's Conditions Card
                                        TodayConditionsCard(
                                            cloudMean: todayCloudMean,
                                            cloudAtSun: todayCloudAtSun,
                                            humidity: todayHumidity,
                                            aod: todayAod
                                        )
                                        
                                        // 10-Day Forecast Card
                                        ForecastCard(forecasts: forecasts)
                                    }
                                    .padding()
                                }
                                .tag(0)
                                
                                // Favorite location pages
                                ForEach(favoritesStore.favorites.indices, id: \.self) { index in
                                    FavoriteLocationView(location: favoritesStore.favorites[index])
                                        .tag(index + 1)
                                }
                            }
                            .onChange(of: tabSelection.homePageIndex) { oldValue, newValue in
                                print("[HomeView] Home page index changed: \(oldValue) -> \(newValue)")
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
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
                } else {
                    // Favorites View
                    FavoritesView()
                }
            }
            
            // Bottom navigation bar with page indicators
            BottomNavBar(
                onLocationTap: {
                    // Reset to current location page
                    tabSelection.homePageIndex = 0
                },
                onFavoritesTap: {
                    // Handle favorites tap
                },
                // Pass total number of pages (current location + favorites)
                totalPages: 1 + favoritesStore.favorites.count
            )
        }
    }

    // MARK: - Header
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

    // MARK: - Today's Score & Times
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

    // MARK: - Networking & Data
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
                forecasts = list
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
}
