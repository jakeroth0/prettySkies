import SwiftUI
import CoreLocation

struct DailyForecast: Identifiable {
    let id:      Date
    let weekday: String
    let score:   Int
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var sunsetService  = SunsetService()

    @State private var locationName: String?
    @State private var forecasts:    [DailyForecast] = []
    @State private var isLoading      = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // ← Use our hex-init with the label
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#FF6B5C"),
                    Color(hex: "#FFB35C"),
                    Color(hex: "#FFD56B")
                ]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let loc = locationName {
                        Text(loc)
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    if let err = errorMessage {
                        Text("Error: \(err)")
                            .foregroundColor(.white)
                    } else if isLoading {
                        Text("Loading…")
                            .foregroundColor(.white)
                    }

                    if !forecasts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("10-Day Forecast")
                                .font(.headline)
                                .foregroundColor(.white)

                            ForEach(forecasts) { day in
                                HStack(spacing: 12) {
                                    Text(day.weekday)
                                        .frame(width: 40, alignment: .leading)
                                        .foregroundColor(.white)
                                    Image(systemName: "cloud.fill")
                                        .foregroundColor(.white)
                                    GeometryReader { geo in
                                        let frac = CGFloat(day.score) / 100
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(height: 6)
                                            Capsule()
                                                .fill(Color.white)
                                                .frame(
                                                    width: geo.size.width * frac,
                                                    height: 6
                                                )
                                        }
                                    }
                                    .frame(height: 6)
                                    Text("\(day.score)%")
                                        .frame(width: 40, alignment: .trailing)
                                        .foregroundColor(.white)
                                }
                                .frame(height: 28)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(12)
                        .padding(.top, 24)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            print("[ContentView] onAppear")
            locationManager.requestLocation()
        }
        .onReceive(locationManager.$coordinate) { coordOpt in
            guard let coord = coordOpt else { return }
            Task {
                print("[ContentView] 📍 Received coord:", coord)
                await fetchLocationName(coord)
                await buildForecasts(for: coord)
            }
        }
    }

    private func fetchLocationName(_ coord: CLLocationCoordinate2D) async {
        let loc = CLLocation(latitude: coord.latitude,
                             longitude: coord.longitude)
        if let p = try? await CLGeocoder().reverseGeocodeLocation(loc).first {
            let parts = [p.locality, p.administrativeArea, p.country]
                .compactMap { $0 }
            let name = parts.joined(separator: ", ")
            print("[ContentView] 🏷 locationName =", name)
            await MainActor.run { locationName = name }
        }
    }

    private func buildForecasts(for coord: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let resp = try await sunsetService.fetchData(
                for: Date(),
                lat: coord.latitude,
                lon: coord.longitude
            )
            let daily  = resp.daily
            let hourly = resp.hourly
            print("[ContentView] 🌄 fetched daily=\(daily.time.count), hourly=\(hourly.time.count)")

            func indexFor(_ isoSun: String) -> Int? {
                let parts = isoSun.split(separator: "T")
                guard parts.count == 2 else { return nil }
                let prefix = "\(parts[0])T\(parts[1].split(separator: ":")[0]):"
                return hourly.time.firstIndex { $0.hasPrefix(prefix) }
            }

            // Use DateFormatter for "yyyy-MM-dd"
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "yyyy-MM-dd"

            var list: [DailyForecast] = []

            for i in daily.time.indices {
                let dayString = daily.time[i]
                guard let dayDate = dayFormatter.date(from: dayString) else {
                    print("[ContentView] ⚠️ Could not parse", dayString)
                    continue
                }
                let weekday = dayDate.formatted(.dateTime.weekday(.abbreviated))
                let sunISO  = daily.sunset[i]

                if i == 0 {
                    // TODAY: hourly cloud layers
                    if let idx = indexFor(sunISO) {
                        let hi  = hourly.cloudcover_high[idx]
                        let mid = hourly.cloudcover_mid[idx]
                        let lo  = hourly.cloudcover_low[idx]
                        let sc  = Int(((hi + mid + lo)/3.0).clamped(to: 0...100))
                        print("[ContentView] Day0 hourly → hi:\(hi) mid:\(mid) lo:\(lo) score:\(sc)")
                        list.append(DailyForecast(id: dayDate, weekday: weekday, score: sc))
                    } else {
                        print("[ContentView] ⚠️ no hourly index for", sunISO)
                    }
                } else {
                    // FUTURE: daily mean
                    let meanCloud = daily.cloudcover_mean[i]
                    let sc        = max(0, 100 - Int(meanCloud))
                    print("[ContentView] Day\(i) daily → meanCloud:\(meanCloud) score:\(sc)")
                    list.append(DailyForecast(id: dayDate, weekday: weekday, score: sc))
                }
            }

            await MainActor.run {
                forecasts = list
                print("[ContentView] 🗓 built \(list.count) forecasts")
            }
        } catch {
            print("[ContentView] ❌ buildForecasts error:", error)
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: — Hex Color Extension

extension Color {
    /// Initialize a SwiftUI Color from a hex string like "#RRGGBB" or "RRGGBB"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255
        )
    }
}

// MARK: — Clamp Helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
