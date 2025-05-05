// SunsetForecast/Views/FavoritesView.swift

import SwiftUI
import CoreLocation
// Import the components we extracted
// FavRow component is used for displaying favorite location cards

struct FavoritesView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore
    @StateObject private var locMgr = LocationManager()
    @StateObject private var searchVM = SearchViewModel()
    @State private var isSearchActive = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Navigation path for programmatic navigation
    @State private var navigationPath = NavigationPath()
    
    // Get the safe area insets to ensure proper positioning
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    // Add state for fullscreen view
    @State private var showFullscreenFavorites = false
    @State private var fullscreenInitialLocation: Location?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack(path: $navigationPath) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        // Space at the top when search is active
                        if isSearchActive {
                            Spacer()
                                .frame(height: 10)
                        }
                        
                        // MARK: - Header
                        HStack {
                            Text("Sunsets")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            // Add fullscreen button
                            if !favoritesStore.favorites.isEmpty && !isSearchActive {
                                Button {
                                    // Use first favorite as initial location
                                    fullscreenInitialLocation = favoritesStore.favorites.first
                                    showFullscreenFavorites = true
                                } label: {
                                    Image(systemName: "rectangle.on.rectangle")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, isSearchActive ? 0 : 8)
                        .opacity(isSearchActive ? 0 : 1)
                        
                        // MARK: - Search Bar
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Search for a city or airport", text: $searchVM.searchText)
                                    .foregroundColor(.white)
                                    .accentColor(.white)
                                    .autocorrectionDisabled()
                                    .focused($isSearchFieldFocused)
                                    .submitLabel(.search)
                                    .onTapGesture {
                                        isSearchFieldFocused = true
                                    }
                            }
                            .padding(10)
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onTapGesture {
                                isSearchFieldFocused = true
                            }
                            
                            if isSearchActive {
                                Button("Cancel") {
                                    isSearchFieldFocused = false
                                    searchVM.searchText = ""
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isSearchActive = false
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal)
                        .offset(y: isSearchActive ? -25 : 0)
                        
                        // MARK: - Loading Indicator
                        if searchVM.isLoading && !searchVM.searchText.isEmpty {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                        
                        // MARK: - Content Area
                        ZStack(alignment: .top) {
                            // MARK: - Favorite Locations
                            List {
                                // — My Location Card —
                                Button {
                                    print("[FavoritesView] Tapped on Current Location")
                                    
                                    // First, clear navigation path if any
                                    navigationPath = NavigationPath()
                                    
                                    // Reset the home page index to show the current location (first page)
                                    TabViewSelection.shared.homePageIndex = 0
                                    
                                    // Then, after a brief delay, switch to the home tab
                                    // This ensures we're already out of any navigation context
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            TabViewSelection.shared.selectedTab = .home
                                        }
                                        // Request location update
                                        locMgr.requestLocation()
                                    }
                                } label: {
                                    FavRow(location: currentLocation(), isCurrentLocation: true)
                                }
                                .buttonStyle(PlainButtonStyle()) // Critical for making taps register
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                
                                // — Saved Favorites —
                                ForEach(favoritesStore.favorites) { loc in
                                    Button {
                                        print("[FavoritesView] Tapped on favorite: \(loc.displayName)")
                                        
                                        // Use direct navigation to LocationDetailView 
                                        // We need to add a small delay to ensure the button tap is
                                        // completed before navigating
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            navigationPath.append(loc)
                                        }
                                    } label: {
                                        FavRow(location: loc, isCurrentLocation: false)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Critical for making taps register
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                    .onLongPressGesture {
                                        // Open fullscreen view with this location
                                        fullscreenInitialLocation = loc
                                        showFullscreenFavorites = true
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        withAnimation {
                                            let locationToRemove = favoritesStore.favorites[index]
                                            favoritesStore.remove(locationToRemove)
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .opacity(isSearchActive ? 0 : 1)
                            
                            // MARK: - Search Results
                            if !searchVM.searchResults.isEmpty && !searchVM.searchText.isEmpty {
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 0) {
                                        ForEach(searchVM.searchResults, id: \.id) { location in
                                            SearchResultRow(location: location) {
                                                Task {
                                                    do {
                                                        // Get the full location details
                                                        let loc = await searchVM.selectLocation(location)
                                                        print("[FavoritesView] Selected search result: \(loc.displayName)")
                                                        
                                                        // Clear search UI
                                                        isSearchFieldFocused = false
                                                        searchVM.searchText = ""
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            isSearchActive = false
                                                        }
                                                        
                                                        // Slight delay to ensure UI transitions finish
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            // Navigate to the preview view
                                                            navigationPath.append(SearchLocationPreview(location: loc))
                                                        }
                                                    } catch {
                                                        print("[FavoritesView] Error loading search result details: \(error)")
                                                    }
                                                }
                                            }
                                            
                                            Divider()
                                                .background(Color.gray.opacity(0.3))
                                                .padding(.leading)
                                        }
                                    }
                                }
                                .opacity(isSearchActive ? 1 : 0)
                            }
                        }
                    }
                }
                
                // MARK: - Navigation Destinations
                // Navigation destination for locations
                .navigationDestination(for: Location.self) { location in
                    // Full detail view for locations
                    LocationDetailView(location: location)
                }
                
                // Add a separate destination for search previews
                .navigationDestination(for: SearchLocationPreview.self) { wrapper in
                    LocationPreview(location: wrapper.location)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isSearchActive)
            .onAppear { 
                locMgr.requestLocation()
            }
            .onChange(of: isSearchFieldFocused) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSearchActive = newValue
                }
            }
            .onChange(of: searchVM.searchText) { oldValue, newValue in
                Task {
                    if !newValue.isEmpty {
                        await searchVM.performSearch()
                    }
                }
            }
            .sheet(isPresented: $showFullscreenFavorites) {
                if let location = fullscreenInitialLocation {
                    FullscreenFavoritesView(
                        initialLocation: location,
                        favoritesStore: favoritesStore
                    )
                    .environmentObject(favoritesStore)
                }
            }
        }
    }

    private func currentLocation() -> Location {
        let coord = locMgr.coordinate
            ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        return Location(
            id: "\(coord.latitude),\(coord.longitude)",
            name: locMgr.lastPlaceName ?? "My Location",
            latitude: coord.latitude,
            longitude: coord.longitude,
            country: "",
            admin1: nil,
            timeZoneIdentifier: TimeZone.current.identifier
        )
    }
}

// MARK: - FavRow Component
private struct FavRow: View {
    let location: Location
    let isCurrentLocation: Bool
    @State private var localTime = "--:--"
    @State private var score = 0
    @State private var aod: Double?
    @State private var errorLoadingScore = false
    @State private var isLoading = false
    
    // Add initializer with default parameter
    init(location: Location, isCurrentLocation: Bool = false) {
        self.location = location
        self.isCurrentLocation = isCurrentLocation
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(location.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isCurrentLocation {
                        Text("📍")
                            .font(.caption)
                    }
                }
                Text(localTime)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                if let aod = aod, aod > 0 {
                    Text("AOD: \(aod, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            Spacer()
            ZStack {
                Text("\(score)%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    isCurrentLocation ? Color(.systemBlue).opacity(0.4) : Color(.systemGray5).opacity(0.6),
                    isCurrentLocation ? Color(.systemBlue).opacity(0.2) : Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(Material.ultraThinMaterial)
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            updateLocalTime()
            updateScore()
        }
    }

    private func updateLocalTime() {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.timeZone = location.timeZone ?? .current
        localTime = fmt.string(from: Date())
        print("[FavRow] \(location.displayName) localTime → \(localTime)")
    }

    private func updateScore() {
        isLoading = true
        
        Task {
            do {
                // Fetch weather data
                let weather = try await SunsetService.shared.fetchData(
                    for: Date(),
                    lat: location.latitude,
                    lon: location.longitude
                )
                
                guard let isoSun = weather.daily.sunset.first,
                      let idx = indexFor(isoSun, in: weather.hourly.time)
                else { 
                    isLoading = false
                    return 
                }
                
                // Calculate cloud coverage at sunset with appropriate weights
                // High and mid clouds contribute positively to sunset colors
                // Low clouds typically diminish sunset quality
                let hi = weather.hourly.cloudcover_high[idx]
                let mi = weather.hourly.cloudcover_mid[idx]
                let lo = weather.hourly.cloudcover_low[idx]
                
                // Apply weighted formula - reward high clouds, neutral for mid, penalize low clouds
                let weightedCloud = (0.4 * hi) + (0.0 * mi) - (0.3 * lo) 
                
                // Scale to 0-100 range, where higher is better cloud conditions for sunset
                let cloudPercent = 50 + Int(weightedCloud.clamped(to: -50...50))
                
                // Try to get air quality data
                var aodValue: Double? = nil
                var clarityScore = 0
                
                do {
                    let airQuality = try await AirQualityService.shared.fetchData(
                        for: Date(),
                        lat: location.latitude,
                        lon: location.longitude
                    )
                    
                    // Find AOD value closest to sunset time
                    aodValue = AirQualityService.shared.findAODForTime(timestamp: isoSun, in: airQuality)
                    
                    // If AOD not available, get fallback values
                    if aodValue == nil {
                        let fallback = AirQualityService.shared.findFallbackValues(timestamp: isoSun, in: airQuality)
                        clarityScore = AirQualityService.shared.calculateClarityScore(aod: nil, dust: fallback.dust, pm25: fallback.pm25)
                    } else {
                        clarityScore = AirQualityService.shared.calculateClarityScore(aod: aodValue, dust: nil, pm25: nil)
                    }
                    
                    print("[FavRow] \(location.displayName) AOD → \(String(describing: aodValue)), clarity: \(clarityScore)")
                } catch {
                    print("[FavRow] Air quality not available: \(error)")
                    // Default to cloud-only score if we can't get air quality
                    clarityScore = 100
                }
                
                // Blend cloud score with clarity score
                // Cloud score is 0-100 where 0 = totally cloudy and 100 = clear
                let finalScore = Int(0.7 * Double(cloudPercent) + 0.3 * Double(clarityScore))
                let clampedScore = max(0, min(100, finalScore))
                
                await MainActor.run {
                    self.score = clampedScore
                    self.aod = aodValue
                    self.isLoading = false
                }
                
                print("[FavRow] \(location.displayName) final score → \(clampedScore)")
            } catch {
                print("[FavRow] error fetching score:", error)
                await MainActor.run {
                    self.errorLoadingScore = true
                    self.isLoading = false
                }
            }
        }
    }

    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let parts = isoSun.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let hourPrefix = parts[1].split(separator: ":")[0]
        let lookup = "\(parts[0])T\(hourPrefix):"
        return hours.firstIndex { $0.hasPrefix(lookup) }
    }
}

// MARK: - Search Location Preview Wrapper
// This wrapper allows us to distinguish between regular locations and search result locations
// for different navigation destinations
struct SearchLocationPreview: Hashable {
    let location: Location
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(location.id)
    }
    
    static func == (lhs: SearchLocationPreview, rhs: SearchLocationPreview) -> Bool {
        return lhs.location.id == rhs.location.id
    }
}

// MARK: - Environment value extension for safe area insets
private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        return EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}
