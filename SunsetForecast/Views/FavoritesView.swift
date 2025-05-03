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
                // Matches your SearchView initializer exactly
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

    /// Builds a “Location” struct for the device’s current spot.
    private func currentLocation() -> Location {
        let coord = locMgr.coordinate
            ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        return Location(
            id: "\(coord.latitude),\(coord.longitude)",
            name: "My Location",
            latitude: coord.latitude,
            longitude: coord.longitude,
            country: "",
            admin1: nil,
            timeZoneIdentifier: TimeZone.current.identifier
        )
    }
}


/// Single row/card showing one location’s name, local time, and sunset score.
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

    /// Formats “now” in the location’s time zone
    private func updateLocalTime() {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.timeZone = location.timeZone ?? TimeZone.current
        localTime = fmt.string(from: Date())
        print("[FavRow] \(location.displayName) localTime → \(localTime)")
    }

    /// Pulls today’s sunset score (hourly cloud average)
    private func updateScore() {
        Task {
            do {
                let resp = try await SunsetService.shared.fetchData(
                    for: Date(),
                    lat: location.latitude,
                    lon: location.longitude
                )
                // find the index for today’s sunset hour
                if let isoSun = resp.daily.sunset.first,
                   let idx   = indexFor(isoSun, in: resp.hourly.time)
                {
                    let hi  = resp.hourly.cloudcover_high[idx]
                    let mi  = resp.hourly.cloudcover_mid[idx]
                    let lo  = resp.hourly.cloudcover_low[idx]
                    let avg = (hi + mi + lo) / 3.0
                    let raw = Int(avg)
                    let clamped = max(0, min(100, raw))
                    await MainActor.run { score = clamped }
                    print("[FavRow] \(location.displayName) score →", clamped)
                }
            } catch {
                print("[FavRow] error fetching score:", error)
            }
        }
    }

    /// Helper to match “2025-05-03T19:” against the hourly times
    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let parts = isoSun.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let hourPrefix = parts[1].split(separator: ":")[0]
        let lookup     = "\(parts[0])T\(hourPrefix):"
        return hours.firstIndex { $0.hasPrefix(lookup) }
    }
}
