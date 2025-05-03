// SunsetForecast/Views/FavoritesView.swift

import SwiftUI
import CoreLocation

struct FavoritesView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore
    @StateObject private var locMgr = LocationManager()
    @State private var showSearch = false
    @State private var selected: Location?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // — My Location Card —
                        Button {
                            selected = nil
                            locMgr.requestLocation()
                        } label: {
                            FavRow(location: currentLocation())
                        }

                        // — Header + Search Button —
                        HStack {
                            Text("Sunsets")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                showSearch = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)

                        // — Saved Favorites —
                        ForEach(favoritesStore.favorites, id: \.self) { loc in
                            Button {
                                selected = loc
                            } label: {
                                FavRow(location: loc)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
                    .environmentObject(favoritesStore)
            }
            .navigationDestination(isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            )) {
                if let loc = selected {
                    LocationDetailView(location: loc)
                }
            }
        }
        .onAppear { locMgr.requestLocation() }
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

private struct FavRow: View {
    let location: Location
    @State private var localTime = "--:--"
    @State private var score     = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(location.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(localTime)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Text("\(score)%")
                .font(.title2)
                .foregroundColor(.white)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .onAppear {
            updateLocalTime()
            updateScore()
        }
    }

    private func updateLocalTime() {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.timeZone   = location.timeZone ?? .current
        localTime      = fmt.string(from: Date())
        print("[FavRow] \(location.displayName) localTime → \(localTime)")
    }

    private func updateScore() {
        Task {
            do {
                // Fetch both weather and air quality data
                async let weatherResp = SunsetService.shared.fetchData(
                    for: Date(),
                    lat: location.latitude,
                    lon: location.longitude
                )
                async let airQualityResp = AirQualityService.shared.fetchData(
                    for: Date(),
                    lat: location.latitude,
                    lon: location.longitude
                )
                
                let (weather, airQuality) = try await (weatherResp, airQualityResp)
                
                guard let isoSun = weather.daily.sunset.first,
                      let idx = indexFor(isoSun, in: weather.hourly.time)
                else { return }
                
                // Get cloud cover at sunset
                let hi = weather.hourly.cloudcover_high[idx]
                let mi = weather.hourly.cloudcover_mid[idx]
                let lo = weather.hourly.cloudcover_low[idx]
                let avg = (hi + mi + lo) / 3.0
                
                // Get AOD at sunset
                let aod = airQuality.hourly.aerosol_optical_depth_340nm[idx]
                
                // For now, just use cloud cover for score
                // TODO: Factor in AOD when we refine the formula
                let raw = Int(avg)
                let clamped = max(0, min(100, raw))
                
                await MainActor.run {
                    score = clamped
                }
                print("[FavRow] \(location.displayName) score →", clamped)
            } catch {
                print("[FavRow] error fetching score:", error)
            }
        }
    }

    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let parts = isoSun.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let hourPrefix = parts[1].split(separator: ":")[0]
        let lookup     = "\(parts[0])T\(hourPrefix):"
        return hours.firstIndex { $0.hasPrefix(lookup) }
    }
}
