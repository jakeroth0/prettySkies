// SunsetForecast/Views/ContentView.swift
// DEPRECATED: This view has been replaced by HomeView.swift

import SwiftUI
import CoreLocation

@available(*, deprecated, message: "This view is deprecated. Use HomeView instead.")
struct ContentView: View {
    // MARK: – State & Services

    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var favoritesStore: FavoritesStore
    private let sunsetService = SunsetService.shared

    @State private var locationName: String?
    @State private var forecasts: [SunsetForecast.DailyForecast] = []

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
    @ObservedObject private var tabSelection = TabViewSelection.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content based on selected tab
            Group {
                if tabSelection.selectedTab == .home {
                    // Home / Details View
                    ZStack {
                        // Always show the background gradient
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
                                        TodayConditionsCard(
                                            cloudMean: todayCloudMean,
                                            cloudAtSun: todayCloudAtSun,
                                            humidity: todayHumidity,
                                            aod: todayAod
                                        )
                                        forecastCardView
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
                                print("[ContentView] Home page index changed: \(oldValue) -> \(newValue)")
                            }
                            // Default page indicators are hidden
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

    // MARK: – 10-Day Forecast Card

    private var forecastCardView: some View {
        // MARK: – 10-Day Forecast
        
        // Use our new ForecastCard component
        ForecastCard(forecasts: forecasts)
        
        // Footer
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
            var list: [SunsetForecast.DailyForecast] = []

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
                list.append(SunsetForecast.DailyForecast(id: d, weekday: wd, score: sc))
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
                list[idx] = SunsetForecast.DailyForecast(
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
    
    // MARK: - Favorite Location View
    
    private func favoriteLocationView(for location: Location) -> some View {
        @State var locationForecast: [SunsetForecast.DailyForecast] = []
        @State var locCloudMean: Double?
        @State var locCloudAtSun: Double?
        @State var locAod: Double?
        @State var locHumidity: Double?
        @State var locSunsetMoment: Date?
        @State var locGoldenMoment: Date?
        @State var isLoadingData = false
        @State var locationError: String?
        
        return ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Favorite Location")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text(location.displayName)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                // Score
                VStack(spacing: 8) {
                    if let score = locationForecast.first?.score {
                        Text("\(score)%")
                            .font(.system(size: 72, weight: .thin))
                            .foregroundColor(.white)
                        HStack(spacing: 16) {
                            if let g = locGoldenMoment {
                                Text("Golden \(g.formatted(.dateTime.hour().minute()))")
                            }
                            if let s = locSunsetMoment {
                                Text("Sunset \(s.formatted(.dateTime.hour().minute()))")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    } else if isLoadingData {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("--")
                            .font(.system(size: 72, weight: .thin))
                            .foregroundColor(.white)
                    }
                }
                
                // Conditions grid (reuse variable card layout)
                if !locationForecast.isEmpty {
                    // Use our TodayConditionsCard component
                    TodayConditionsCard(
                        cloudMean: locCloudMean,
                        cloudAtSun: locCloudAtSun,
                        humidity: locHumidity,
                        aod: locAod
                    )
                    
                    // Forecast
                    if locationForecast.count > 1 {
                        // Use our ForecastCard component
                        ForecastCard(
                            forecasts: locationForecast,
                            title: "5-Day Forecast"
                        )
                    }
                }
            }
            .padding()
            .onAppear {
                Task {
                    isLoadingData = true
                    do {
                        // Load data for this favorite location
                        let coord = CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                        
                        let resp = try await sunsetService.fetchData(
                            for: Date(),
                            lat: coord.latitude,
                            lon: coord.longitude
                        )
                        
                        // Process data similar to loadData method
                        let dayFmt = DateFormatter()
                        dayFmt.dateFormat = "yyyy-MM-dd"
                        var list: [SunsetForecast.DailyForecast] = []
                        
                        for i in resp.daily.time.indices {
                            guard let d = dayFmt.date(from: resp.daily.time[i]) else { continue }
                            let wd = d.formatted(.dateTime.weekday(.abbreviated))
                            let sc: Int
                            if i == 0, let idx = indexFor(resp.daily.sunset[i], in: resp.hourly.time) {
                                let hi = resp.hourly.cloudcover_high[idx]
                                let mi = resp.hourly.cloudcover_mid[idx]
                                let lo = resp.hourly.cloudcover_low[idx]
                                let totalCloud = resp.hourly.cloudcover[idx]
                                
                                let weightedCloud = (0.4 * hi) + (0.0 * mi) - (0.3 * lo)
                                sc = 50 + Int(weightedCloud.clamped(to: -50...50))
                                
                                locCloudAtSun = totalCloud
                                locHumidity = resp.hourly.relativehumidity_2m[idx]
                            } else {
                                sc = max(0, 100 - Int(resp.daily.cloudcover_mean[i]))
                            }
                            list.append(SunsetForecast.DailyForecast(id: d, weekday: wd, score: sc))
                        }
                        
                        // Set times
                        let sunFmt = DateFormatter()
                        sunFmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
                        if let sunD = sunFmt.date(from: resp.daily.sunset[0]) {
                            locSunsetMoment = sunD
                            locGoldenMoment = sunD.addingTimeInterval(-1800)
                        }
                        locCloudMean = resp.daily.cloudcover_mean[0]
                        
                        // Try to get air quality data
                        do {
                            let aqResp = try await AirQualityService.shared.fetchData(
                                for: Date(), 
                                lat: coord.latitude, 
                                lon: coord.longitude
                            )
                            
                            if let sunsetTime = resp.daily.sunset.first {
                                locAod = AirQualityService.shared.findAODForTime(
                                    timestamp: sunsetTime,
                                    in: aqResp
                                )
                                
                                // Apply clarity adjustments
                                if let idx = list.indices.first, let firstDay = list.first, let aod = locAod {
                                    let clarityScore = AirQualityService.shared.calculateClarityScore(
                                        aod: aod, 
                                        dust: nil, 
                                        pm25: nil
                                    )
                                    
                                    let finalScore = Int(0.7 * Double(firstDay.score) + 0.3 * Double(clarityScore))
                                    let clampedScore = max(0, min(100, finalScore))
                                    
                                    list[idx] = SunsetForecast.DailyForecast(
                                        id: firstDay.id, 
                                        weekday: firstDay.weekday, 
                                        score: clampedScore
                                    )
                                }
                            }
                        } catch {
                            print("[FavoriteView] Air quality error for \(location.displayName):", error)
                        }
                        
                        // Update UI
                        locationForecast = list
                        locationError = nil
                        
                    } catch {
                        print("[FavoriteView] Error loading data for \(location.displayName):", error)
                        locationError = error.localizedDescription
                    }
                    
                    isLoadingData = false
                }
            }
        }
    }
}

// Replace with:

// MARK: - Favorite Location View

struct FavoriteLocationView: View {
    let location: Location
    private let sunsetService = SunsetService.shared
    
    @State private var locationForecast: [SunsetForecast.DailyForecast] = []
    @State private var locCloudMean: Double?
    @State private var locCloudAtSun: Double?
    @State private var locAod: Double?
    @State private var locHumidity: Double?
    @State private var locSunsetMoment: Date?
    @State private var locGoldenMoment: Date?
    @State private var isLoadingData = false
    @State private var locationError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Favorite Location")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text(location.displayName)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                // Score
                VStack(spacing: 8) {
                    if let score = locationForecast.first?.score {
                        Text("\(score)%")
                            .font(.system(size: 72, weight: .thin))
                            .foregroundColor(.white)
                        HStack(spacing: 16) {
                            if let g = locGoldenMoment {
                                Text("Golden \(g.formatted(.dateTime.hour().minute()))")
                            }
                            if let s = locSunsetMoment {
                                Text("Sunset \(s.formatted(.dateTime.hour().minute()))")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    } else if isLoadingData {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("--")
                            .font(.system(size: 72, weight: .thin))
                            .foregroundColor(.white)
                    }
                }
                
                // Conditions grid (reuse variable card layout)
                if !locationForecast.isEmpty {
                    // Use our TodayConditionsCard component
                    TodayConditionsCard(
                        cloudMean: locCloudMean,
                        cloudAtSun: locCloudAtSun,
                        humidity: locHumidity,
                        aod: locAod
                    )
                    
                    // Forecast
                    if locationForecast.count > 1 {
                        // Use our ForecastCard component
                        ForecastCard(
                            forecasts: locationForecast,
                            title: "5-Day Forecast"
                        )
                    }
                }
            }
            .padding()
            .onAppear {
                Task {
                    isLoadingData = true
                    do {
                        // Load data for this favorite location
                        let coord = CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                        
                        let resp = try await sunsetService.fetchData(
                            for: Date(),
                            lat: coord.latitude,
                            lon: coord.longitude
                        )
                        
                        // Process data similar to loadData method
                        let dayFmt = DateFormatter()
                        dayFmt.dateFormat = "yyyy-MM-dd"
                        var list: [SunsetForecast.DailyForecast] = []
                        
                        for i in resp.daily.time.indices {
                            guard let d = dayFmt.date(from: resp.daily.time[i]) else { continue }
                            let wd = d.formatted(.dateTime.weekday(.abbreviated))
                            let sc: Int
                            if i == 0, let idx = indexFor(resp.daily.sunset[i], in: resp.hourly.time) {
                                let hi = resp.hourly.cloudcover_high[idx]
                                let mi = resp.hourly.cloudcover_mid[idx]
                                let lo = resp.hourly.cloudcover_low[idx]
                                let totalCloud = resp.hourly.cloudcover[idx]
                                
                                let weightedCloud = (0.4 * hi) + (0.0 * mi) - (0.3 * lo)
                                sc = 50 + Int(weightedCloud.clamped(to: -50...50))
                                
                                locCloudAtSun = totalCloud
                                locHumidity = resp.hourly.relativehumidity_2m[idx]
                            } else {
                                sc = max(0, 100 - Int(resp.daily.cloudcover_mean[i]))
                            }
                            list.append(SunsetForecast.DailyForecast(id: d, weekday: wd, score: sc))
                        }
                        
                        // Set times
                        let sunFmt = DateFormatter()
                        sunFmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
                        if let sunD = sunFmt.date(from: resp.daily.sunset[0]) {
                            locSunsetMoment = sunD
                            locGoldenMoment = sunD.addingTimeInterval(-1800)
                        }
                        locCloudMean = resp.daily.cloudcover_mean[0]
                        
                        // Try to get air quality data
                        do {
                            let aqResp = try await AirQualityService.shared.fetchData(
                                for: Date(), 
                                lat: coord.latitude, 
                                lon: coord.longitude
                            )
                            
                            if let sunsetTime = resp.daily.sunset.first {
                                locAod = AirQualityService.shared.findAODForTime(
                                    timestamp: sunsetTime,
                                    in: aqResp
                                )
                                
                                // Apply clarity adjustments
                                if let idx = list.indices.first, let firstDay = list.first, let aod = locAod {
                                    let clarityScore = AirQualityService.shared.calculateClarityScore(
                                        aod: aod, 
                                        dust: nil, 
                                        pm25: nil
                                    )
                                    
                                    let finalScore = Int(0.7 * Double(firstDay.score) + 0.3 * Double(clarityScore))
                                    let clampedScore = max(0, min(100, finalScore))
                                    
                                    list[idx] = SunsetForecast.DailyForecast(
                                        id: firstDay.id, 
                                        weekday: firstDay.weekday, 
                                        score: clampedScore
                                    )
                                }
                            }
                        } catch {
                            print("[FavoriteView] Air quality error for \(location.displayName):", error)
                        }
                        
                        // Update UI
                        locationForecast = list
                        locationError = nil
                        
                    } catch {
                        print("[FavoriteView] Error loading data for \(location.displayName):", error)
                        locationError = error.localizedDescription
                    }
                    
                    isLoadingData = false
                }
            }
        }
    }
    
    // Helper functions
    
    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let parts = isoSun.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let lookup = "\(parts[0])T\(parts[1].split(separator: ":")[0]):"
        return hours.firstIndex { $0.hasPrefix(lookup) }
    }
    
    private func labelCloudMean(_ v: Double) -> String {
        v < 20 ? "Clear" :
        v < 60 ? "Partly" :
               "Overcast"
    }
    
    private func labelHumidity(_ v: Double) -> String {
        v < 40 ? "Dry" :
        v < 70 ? "OK" :
               "Humid"
    }
    
    private func labelAOD(_ v: Double) -> String {
        v < 0.1 ? "Low" :
        v < 0.3 ? "Mod" :
               "High"
    }
    
    private func variableTile(icon: String, title: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 20)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }
}

