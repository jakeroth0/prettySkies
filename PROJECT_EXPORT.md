# PrettySkies Project Export

## Project Structure
```
SunsetForecast/
├── Models/
│   ├── Location.swift
│   └── ForecastResponse.swift
├── Services/
│   ├── SunsetService.swift
│   ├── LocationSearchService.swift
│   └── OpenMeteoSearchService.swift
├── ViewModels/
│   └── SearchViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── SearchView.swift
│   └── LocationDetailView.swift
├── Location/
│   └── LocationManager.swift
├── Helpers/
│   └── Color+Hex.swift
├── Assets/
│   └── sunset_icon.png
├── Assets.xcassets/
├── Info.plist
└── SunsetForecastApp.swift
```

## Key Files

### Models/Location.swift
```swift
import Foundation

struct Location: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?
    let timeZoneIdentifier: String
    
    var coordinates: String {
        return "\(latitude),\(longitude)"
    }
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }
}
```

### Models/ForecastResponse.swift
```swift
import Foundation

struct ForecastResponse: Codable {
    let daily: RawDaily
    let hourly: RawHourly
    
    struct RawDaily: Codable {
        let time: [String]
        let sunset: [String]
        let sunrise: [String]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let precipitationProbabilityMax: [Int]
        let weatherCode: [Int]
        let windSpeed10mMax: [Double]
        let windGusts10mMax: [Double]
        let windDirection10mDominant: [Int]
        let cloudCoverMax: [Int]
        let visibilityMax: [Double]
        let uvIndexMax: [Double]
    }
    
    struct RawHourly: Codable {
        let time: [String]
        let temperature2m: [Double]
        let relativeHumidity2m: [Int]
        let dewPoint2m: [Double]
        let apparentTemperature: [Double]
        let precipitation: [Double]
        let rain: [Double]
        let showers: [Double]
        let snowfall: [Double]
        let precipitationProbability: [Int]
        let weatherCode: [Int]
        let pressureMsl: [Double]
        let surfacePressure: [Double]
        let cloudCover: [Int]
        let cloudCoverLow: [Int]
        let cloudCoverMid: [Int]
        let cloudCoverHigh: [Int]
        let visibility: [Double]
        let evapotranspiration: [Double]
        let vapourPressureDeficit: [Double]
        let windSpeed10m: [Double]
        let windSpeed100m: [Double]
        let windDirection10m: [Int]
        let windDirection100m: [Int]
        let windGusts10m: [Double]
        let soilTemperature0cm: [Double]
        let soilTemperature6cm: [Double]
        let soilTemperature18cm: [Double]
        let soilTemperature54cm: [Double]
        let soilMoisture0To1cm: [Double]
        let soilMoisture1To3cm: [Double]
        let soilMoisture3To9cm: [Double]
        let soilMoisture9To27cm: [Double]
        let soilMoisture27To81cm: [Double]
    }
}
```

### Services/SunsetService.swift
```swift
import Foundation
import CoreLocation

class SunsetService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    
    func fetchForecast(for location: Location) async throws -> ForecastResponse {
        let urlString = "\(baseURL)?latitude=\(location.latitude)&longitude=\(location.longitude)&timezone=\(location.timeZoneIdentifier)&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant,cloud_cover_max,visibility_max,uv_index_max&hourly=temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,precipitation,rain,showers,snowfall,precipitation_probability,weather_code,pressure_msl,surface_pressure,cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,visibility,evapotranspiration,vapour_pressure_deficit,wind_speed_10m,wind_speed_100m,wind_direction_10m,wind_direction_100m,wind_gusts_10m,soil_temperature_0cm,soil_temperature_6cm,soil_temperature_18cm,soil_temperature_54cm,soil_moisture_0_to_1cm,soil_moisture_1_to_3cm,soil_moisture_3_to_9cm,soil_moisture_9_to_27cm,soil_moisture_27_to_81cm"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ForecastResponse.self, from: data)
    }
}
```

### Services/LocationSearchService.swift
```swift
import Foundation

protocol LocationSearchService {
    func search(_ query: String) async throws -> [Location]
}
```

### Services/OpenMeteoSearchService.swift
```swift
import Foundation

struct OpenMeteoSearchService: LocationSearchService {
    private let baseURL = "https://geocoding-api.open-meteo.com/v1/search"
    
    func search(_ query: String) async throws -> [Location] {
        let urlString = "\(baseURL)?name=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&count=10&language=en&format=json"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(SearchResponse.self, from: data)
        
        return searchResponse.results.map { result in
            Location(
                id: "\(result.latitude),\(result.longitude)",
                name: result.name,
                latitude: result.latitude,
                longitude: result.longitude,
                country: result.country ?? "",
                admin1: result.admin1,
                timeZoneIdentifier: TimeZone.current.identifier
            )
        }
    }
    
    private struct SearchResponse: Codable {
        let results: [SearchResult]
    }
    
    private struct SearchResult: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String?
    }
}
```

### ViewModels/SearchViewModel.swift
```swift
import Foundation
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Location] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let searchService: LocationSearchService
    
    init(searchService: LocationSearchService = OpenMeteoSearchService()) {
        self.searchService = searchService
    }
    
    func performSearch() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let results = try await searchService.search(searchText)
            searchResults = results
        } catch {
            self.error = error
            searchResults = []
        }
        
        isLoading = false
    }
}
```

### Views/ContentView.swift
```swift
import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = 0
    @State private var sunsetTime: String?
    @State private var error: Error?
    @State private var isLoading = false
    @State private var score: Int?
    @State private var todayRh: Int?
    @State private var todayAod: Double?
    
    private let sunsetService = SunsetService()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "1a1a1a"),
                            Color(hex: "2d2d2d")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Location header
                        if let location = locationManager.currentLocation {
                            Text(location.name)
                                .font(.title)
                                .foregroundColor(.white)
                            
                            Text("\(location.latitude), \(location.longitude)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Sunset time display
                        if let sunsetTime = sunsetTime {
                            VStack(spacing: 8) {
                                Text("Today's Sunset")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(sunsetTime)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(hex: "333333"))
                            )
                        }
                        
                        // Score display
                        if let score = score {
                            VStack(spacing: 8) {
                                Text("Sunset Score")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("\(score)/100")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(scoreColor(score))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(hex: "333333"))
                            )
                        }
                        
                        // Error display
                        if let error = error {
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        // Loading indicator
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                await fetchSunsetData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Search Tab
            NavigationView {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)
        }
        .accentColor(.orange)
        .onAppear {
            Task {
                await fetchSunsetData()
            }
        }
    }
    
    private func fetchSunsetData() async {
        guard let location = locationManager.currentLocation else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location not available"])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let resp = try await sunsetService.fetchForecast(for: location)
            let daily = resp.daily
            let hourly = resp.hourly
            
            // Get today's sunset time
            if let todaySunset = daily.sunset.first {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                if let date = formatter.date(from: todaySunset) {
                    formatter.dateFormat = "h:mm a"
                    sunsetTime = formatter.string(from: date)
                }
            }
            
            // Calculate score based on hourly data
            if let sunsetIndex = hourly.time.firstIndex(where: { $0.contains("18:00") }) {
                let cloudCover = hourly.cloudCover[sunsetIndex]
                let windSpeed = hourly.windSpeed10m[sunsetIndex]
                let precipitation = hourly.precipitation[sunsetIndex]
                
                // Simple scoring algorithm
                var tempScore = 100
                
                // Reduce score based on cloud cover
                tempScore -= Int(Double(cloudCover) * 0.5)
                
                // Reduce score based on wind speed
                tempScore -= Int(windSpeed * 2)
                
                // Reduce score based on precipitation
                tempScore -= Int(precipitation * 10)
                
                // Ensure score is between 0 and 100
                score = max(0, min(100, tempScore))
            }
            
            // Set today's values to nil since they're not available in the API response
            todayRh = nil
            todayAod = nil
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 0..<30:
            return .red
        case 30..<60:
            return .orange
        case 60..<80:
            return .yellow
        default:
            return .green
        }
    }
}

#Preview {
    ContentView()
}
```

### Views/SearchView.swift
```swift
import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1a1a1a"),
                    Color(hex: "2d2d2d")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search locations...", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.white)
                        .onChange(of: viewModel.searchText) { _ in
                            Task {
                                await viewModel.performSearch()
                            }
                        }
                }
                .padding()
                
                // Results list
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(viewModel.searchResults) { location in
                        NavigationLink(destination: LocationDetailView(location: location)) {
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .foregroundColor(.white)
                                if let admin1 = location.admin1 {
                                    Text(admin1)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SearchView()
    }
}
```

### Views/LocationDetailView.swift
```swift
import SwiftUI

struct LocationDetailView: View {
    let location: Location
    @State private var forecast: ForecastResponse?
    @State private var error: Error?
    @State private var isLoading = false
    
    private let sunsetService = SunsetService()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1a1a1a"),
                    Color(hex: "2d2d2d")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Location header
                    VStack(spacing: 8) {
                        Text(location.name)
                            .font(.title)
                            .foregroundColor(.white)
                        
                        if let admin1 = location.admin1 {
                            Text(admin1)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(location.latitude), \(location.longitude)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    // Forecast data
                    if let forecast = forecast {
                        // Today's forecast
                        VStack(spacing: 15) {
                            Text("Today's Forecast")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let todaySunset = forecast.daily.sunset.first {
                                Text("Sunset: \(formatTime(todaySunset))")
                                    .foregroundColor(.white)
                            }
                            
                            if let todaySunrise = forecast.daily.sunrise.first {
                                Text("Sunrise: \(formatTime(todaySunrise))")
                                    .foregroundColor(.white)
                            }
                            
                            if let maxTemp = forecast.daily.temperature2mMax.first {
                                Text("High: \(Int(maxTemp))°")
                                    .foregroundColor(.white)
                            }
                            
                            if let minTemp = forecast.daily.temperature2mMin.first {
                                Text("Low: \(Int(minTemp))°")
                                    .foregroundColor(.white)
                            }
                            
                            if let precipProb = forecast.daily.precipitationProbabilityMax.first {
                                Text("Precipitation: \(precipProb)%")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(hex: "333333"))
                        )
                        
                        // Hourly forecast
                        VStack(spacing: 15) {
                            Text("Hourly Forecast")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(0..<min(24, forecast.hourly.time.count), id: \.self) { index in
                                        VStack(spacing: 8) {
                                            Text(formatHour(forecast.hourly.time[index]))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            Text("\(Int(forecast.hourly.temperature2m[index]))°")
                                                .foregroundColor(.white)
                                            
                                            Text("\(forecast.hourly.precipitationProbability[index])%")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(hex: "333333"))
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(hex: "333333"))
                        )
                    }
                    
                    // Error display
                    if let error = error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Loading indicator
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await fetchForecast()
            }
        }
    }
    
    private func fetchForecast() async {
        isLoading = true
        error = nil
        
        do {
            forecast = try await sunsetService.fetchForecast(for: location)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return timeString
    }
    
    private func formatHour(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "ha"
            return formatter.string(from: date)
        }
        return timeString
    }
}

#Preview {
    NavigationView {
        LocationDetailView(
            location: Location(
                id: "1",
                name: "San Francisco",
                latitude: 37.7749,
                longitude: -122.4194,
                country: "United States",
                admin1: "California",
                timeZoneIdentifier: "America/Los_Angeles"
            )
        )
    }
}
```

### Location/LocationManager.swift
```swift
import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var currentLocation: Location?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first else { return }
            
            let location = Location(
                id: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
                name: placemark.locality ?? "Unknown Location",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                country: placemark.country ?? "",
                admin1: placemark.administrativeArea,
                timeZoneIdentifier: TimeZone.current.identifier
            )
            
            DispatchQueue.main.async {
                self.currentLocation = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
```

### Helpers/Color+Hex.swift
```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### SunsetForecastApp.swift
```swift
import SwiftUI

@main
struct SunsetForecastApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Development Notes

### Technologies Used
- SwiftUI for the user interface
- CoreLocation for location services
- Open-Meteo API for weather data

### Key Features
1. Location-based sunset forecasts
2. Search functionality for locations
3. Detailed weather information
4. Dark mode UI with custom gradients

### API Integration
- Uses Open-Meteo's geocoding API for location search
- Uses Open-Meteo's forecast API for weather data
- Implements proper error handling and loading states

### UI Components
- Tab-based navigation
- Search interface with real-time results
- Detailed location view with hourly forecasts
- Custom color scheme with dark mode support

### Data Models
- Location model for storing location information
- ForecastResponse model for weather data
- Proper separation of concerns with ViewModels

### Future Improvements
1. Add favorites functionality
2. Add more weather parameters
3. Implement caching for offline support
4. Add weather alerts
5. Improve error handling and user feedback
6. Add more customization options 