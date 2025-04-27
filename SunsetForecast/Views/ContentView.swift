import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var sunsetService  = SunsetService()

    @State private var locationName: String?
    @State private var sunsetTime:  String?
    @State private var score:       Int?
    @State private var isLoading:   Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Gradient background
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

            VStack(spacing: 8) {
                // 1. Location name
                if let locName = locationName {
                    Text(locName)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                // 2. Sunset time & score
                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.white)

                } else if isLoading {
                    Text("Loading…")
                        .foregroundColor(.white)

                } else if let time = sunsetTime, let s = score {
                    Text("Sunset Time")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(time)
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Score: \(s)/100")
                        .font(.title2)
                        .foregroundColor(.white)

                } else {
                    Text("Waiting for data…")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .onAppear {
            print("[ContentView] onAppear")
            locationManager.requestLocation()
        }
        .onReceive(locationManager.$coordinate) { newCoord in
            if let coord = newCoord {
                print("[ContentView] Received coordinate:", coord)
                Task {
                    // Reverse-geocode and fetch data in parallel
                    await fetchLocationName(coord)
                    await loadSunset(for: coord)
                }
            } else {
                print("[ContentView] coordinate is still nil")
            }
        }
    }

    // MARK: - Reverse Geocoding

    private func fetchLocationName(_ coord: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coord.latitude,
                                  longitude: coord.longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let place = placemarks.first {
                let city    = place.locality ?? ""
                let region  = place.administrativeArea ?? ""
                let country = place.country ?? ""
                let display = [city, region, country]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                print("[ContentView] locationName set to:", display)
                await MainActor.run { locationName = display }
            }
        } catch {
            print("[ContentView] reverseGeocode error:", error)
        }
    }

    // MARK: - Fetch Sunset & Score

    private func loadSunset(for coord: CLLocationCoordinate2D) async {
        print("[ContentView] loadSunset(start) for:", coord)
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await sunsetService.fetchSunset(
                for: Date(),
                lat: coord.latitude,
                lon: coord.longitude
            )
            let daily = response.daily

            guard daily.sunset.count > 0,
                  daily.cloudcover_mean.count > 0 else {
                errorMessage = "Incomplete data from API"
                return
            }

            // Extract time and score
            let isoString  = daily.sunset[0]
            let cloudCover = daily.cloudcover_mean[0]

            if let timePart = isoString.split(separator: "T").last {
                sunsetTime = String(timePart)
                print("[ContentView] sunsetTime set to:", sunsetTime!)
            }

            score = max(0, 100 - Int(cloudCover))
            print("[ContentView] score set to:", score!)

        } catch {
            errorMessage = error.localizedDescription
            print("[ContentView] loadSunset(error):", error)
        }
    }
}

// MARK: - Static Preview

struct StaticContentView_Preview: View {
    var body: some View {
        ZStack {
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

            VStack(spacing: 8) {
                Text("Cupertino, CA")   // sample locale
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Sunset Time")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("7:55 PM")
                    .font(.title)
                    .foregroundColor(.white)
                Text("Score: 30/100")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StaticContentView_Preview()
                .previewDisplayName("Static Data Preview")
            ContentView()
                .previewDisplayName("Live Preview (no location)")
        }
    }
}

// MARK: - Hex Color Extension

extension Color {
    /// Initialize a Color from a hex string, e.g. "#FF6B5C"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3:
            (r, g, b, a) = ((int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17,
                            255)
        case 6:
            (r, g, b, a) = (int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF,
                            255)
        case 8:
            (r, g, b, a) = (int >> 24 & 0xFF,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (r, g, b, a) = (1, 1, 1, 255)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
