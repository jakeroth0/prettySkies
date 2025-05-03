// SunsetForecast/Views/FavoritesView.swift

import SwiftUI
import CoreLocation
import MapKit

/// Reusable “card” view showing a title, a local time, and an optional % score.
struct FavoriteCardView: View {
    let title: String
    let time:  String
    let score: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Text(time)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if let s = score {
                    Text("\(s)%")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                } else {
                    Text("--%")
                        .font(.title2.bold())
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

/// A single favorite row: shows local time *and* today's sunset score at that location.
struct FavoriteLocationRow: View {
    let loc: Location

    @State private var localTime = "--:--"
    @State private var score: Int? = nil
    @StateObject private var sunsetService = SunsetService()

    var body: some View {
        FavoriteCardView(
            title: loc.name,
            time:  localTime,
            score: score
        )
        .onAppear {
            loadLocalTime()
            loadScore()
        }
    }

    private func loadLocalTime() {
        let cl = CLLocation(latitude: loc.latitude,
                            longitude: loc.longitude)
        CLGeocoder().reverseGeocodeLocation(cl) { places, err in
            guard let tz = places?.first?.timeZone else {
                print("[FavRow] no TZ for \(loc.name): \(err?.localizedDescription ?? "unknown")")
                return
            }
            let df = DateFormatter()
            df.timeZone   = tz
            df.dateFormat = "h:mm a"
            let nowLocal  = df.string(from: Date())
            DispatchQueue.main.async {
                localTime = nowLocal
            }
            print("[FavRow] \(loc.name) localTime →", nowLocal)
        }
    }

    private func loadScore() {
        Task {
            do {
                let resp = try await sunsetService.fetchData(
                    for: Date(),
                    lat: loc.latitude,
                    lon: loc.longitude
                )
                // find the hour index for today’s sunset
                if let isoSun = resp.daily.sunset.first,
                   let idx   = indexFor(isoSun, in: resp.hourlyWeather.time)
                {
                    let hi = resp.hourlyWeather.cloudcover_high[idx]
                    let mi = resp.hourlyWeather.cloudcover_mid[idx]
                    let lo = resp.hourlyWeather.cloudcover_low[idx]
                    let avg = (hi + mi + lo) / 3.0
                    let raw = Int(avg)
                    let clamped = max(0, min(100, raw))
                    await MainActor.run { score = clamped }
                    print("[FavRow] \(loc.name) score →", clamped)
                }
            } catch {
                print("[FavRow] error fetching score for \(loc.name):", error)
            }
        }
    }

    /// Copy of the helper from ContentView to match hour strings like "2025-05-03T19:"
    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let parts = isoSun.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let hourPrefix = parts[1]
            .split(separator: ":")[0]
        let lookup = "\(parts[0])T\(hourPrefix):"
        return hours.firstIndex { $0.hasPrefix(lookup) }
    }
}


struct FavoritesView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore
    @StateObject private var locationManager = LocationManager()
    @State private var myName  : String?
    @State private var myTime  = "--:--"
    @State private var myScore : Int? = nil
    @StateObject private var mySunsetService = SunsetService()

    @State private var searchText = ""
    @StateObject private var completerDelegate = CompleterDelegate()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    // —————————————————————————————————————
                    // Title
                    Text("Sunsets")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    // Search bar
                    EmptyView()
                        .searchable(
                            text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: "Search for a city or airport"
                        )
                        .onChange(of: searchText) { _, new in
                            completerDelegate.queryFragment = new
                        }
                        .frame(height: 0)

                    // —————————————————————————————————————
                    // Cards scroll
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            // 1) Current Location card
                            NavigationLink {
                                ContentView(fixedLocation: nil)
                                    .environmentObject(favoritesStore)
                                    .ignoresSafeArea()
                            } label: {
                                FavoriteCardView(
                                    title: myName ?? "My Location",
                                    time:  myTime,
                                    score: myScore
                                )
                            }
                            .buttonStyle(.plain)

                            // 2) Saved favorites
                            ForEach(favoritesStore.favorites) { loc in
                                NavigationLink(value: loc) {
                                    FavoriteLocationRow(loc: loc)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .onAppear {
                locationManager.requestLocation()
                updateMyTime()
            }
            .onReceive(locationManager.$coordinate) { opt in
                guard let c = opt else { return }
                Task {
                    await fetchMyName(for: c)
                    updateMyTime()
                    await fetchMyScore(for: c)
                }
            }
            .navigationDestination(for: Location.self) { loc in
                ContentView(fixedLocation: loc)
                    .environmentObject(favoritesStore)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: – My Location helpers

    private func updateMyTime() {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        myTime = df.string(from: Date())
        print("[Favorites] My time →", myTime)
    }

    private func fetchMyName(for coord: CLLocationCoordinate2D) async {
        let cl = CLLocation(latitude: coord.latitude,
                            longitude: coord.longitude)
        if let p = try? await CLGeocoder()
            .reverseGeocodeLocation(cl)
            .first
        {
            let parts = [p.locality,
                         p.administrativeArea,
                         p.country]
                .compactMap { $0 }
            let name = parts.joined(separator: ", ")
            await MainActor.run { myName = name }
            print("[Favorites] My name →", name)
        }
    }

    private func fetchMyScore(for coord: CLLocationCoordinate2D) async {
        do {
            let resp = try await mySunsetService.fetchData(
                for: Date(),
                lat: coord.latitude,
                lon: coord.longitude
            )
            // same hourly‐at‐sunset logic
            if let isoSun = resp.daily.sunset.first,
               let idx   = indexFor(isoSun, in: resp.hourlyWeather.time)
            {
                let hi = resp.hourlyWeather.cloudcover_high[idx]
                let mi = resp.hourlyWeather.cloudcover_mid[idx]
                let lo = resp.hourlyWeather.cloudcover_low[idx]
                let avg = (hi + mi + lo) / 3.0
                let raw = Int(avg)
                let clamped = max(0, min(100, raw))
                await MainActor.run { myScore = clamped }
                print("[Favorites] My score →", clamped)
            }
        } catch {
            print("[Favorites] error fetching my score:", error)
        }
    }

    /// We need this here too for navigating into a Location
    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let parts = isoSun.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let hourPrefix = parts[1].split(separator: ":")[0]
        let lookup = "\(parts[0])T\(hourPrefix):"
        return hours.firstIndex { $0.hasPrefix(lookup) }
    }
}


/// MKLocalSearchCompleter helper
private class CompleterDelegate: NSObject,
                                 ObservableObject,
                                 MKLocalSearchCompleterDelegate
{
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate    = self
        completer.resultTypes = .address
    }

    var queryFragment: String {
        get { completer.queryFragment }
        set { completer.queryFragment = newValue }
    }

    func completerDidUpdateResults(_ comp: MKLocalSearchCompleter) {
        DispatchQueue.main.async { self.results = comp.results }
    }
    func completer(_ comp: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("[Search] completer error:", error)
    }
}
