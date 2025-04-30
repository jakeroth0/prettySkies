import SwiftUI
import CoreLocation

struct DailyForecast: Identifiable {
    let id:      Date
    let weekday: String
    let score:   Int
}

struct ContentView: View {
    // MARK: – State & Services

    @StateObject private var locationManager = LocationManager()
    @StateObject private var sunsetService   = SunsetService()

    @State private var locationName: String?
    @State private var forecasts:    [DailyForecast] = []

    // Today's detailed values
    @State private var todayCloudMean: Double?
    @State private var todayHighCloud: Double?
    @State private var todayRh: Double?
    @State private var todayAod: Double?
    @State private var sunsetMoment: Date?
    @State private var goldenMoment: Date?

    @State private var isLoading     = false
    @State private var errorMessage: String?
    @State private var lastCoord: CLLocationCoordinate2D?

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

            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    todayScoreView
                    variableCardView
                    forecastCardView
                }
                .padding()
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onReceive(locationManager.$coordinate) { coordOpt in
            guard let coord = coordOpt else { return }
            // Only fetch once per unique coordinate
            if let last = lastCoord,
               last.latitude == coord.latitude &&
               last.longitude == coord.longitude {
                return
            }
            lastCoord = coord
            Task {
                await fetchLocationName(coord)
                await loadData(for: coord)
            }
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

    // MARK: – Today’s Score & Times

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

    // MARK: – Today’s Conditions Grid

    private var variableCardView: some View {
        VStack(spacing: 12) {
            Text("Today’s Conditions")
                .font(.headline)
                .foregroundColor(.white)
            if let cm = todayCloudMean,
               let hi = todayHighCloud,
               let rh = todayRh,
               let ao = todayAod {
                LazyVGrid(columns: [GridItem(), GridItem()]) {
                    variableTile(icon: "cloud.fill",
                                 title: "Clouds",
                                 label: labelCloudMean(cm))
                    variableTile(icon: "cloud.sun.fill",
                                 title: "High",
                                 label: labelHighCloud(hi))
                    variableTile(icon: "humidity",
                                 title: "Humidity",
                                 label: labelHumidity(rh))
                    variableTile(icon: "sun.haze.fill",
                                 title: "AOD",
                                 label: labelAOD(ao))
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
        isLoading = true
        defer { isLoading = false }

        do {
            let resp = try await sunsetService.fetchData(
                for: Date(),
                lat: coord.latitude,
                lon: coord.longitude
            )
            let daily     = resp.daily
            let hourlyW   = resp.hourlyWeather    // weather‐hourly
            let hourlyAir = resp.hourlyAir        // air‐quality hourly
            print("[Data] got daily=\(daily.time.count), hourlyW=\(hourlyW.time.count), hourlyAir=\(hourlyAir.time.count)")

            // Build 10-day list
            let dayFmt = DateFormatter()
            dayFmt.dateFormat = "yyyy-MM-dd"
            var list: [DailyForecast] = []
            for i in daily.time.indices {
                guard let d = dayFmt.date(from: daily.time[i]) else { continue }
                let wd = d.formatted(.dateTime.weekday(.abbreviated))
                let sc: Int
                if i == 0,
                   let idx = indexFor(daily.sunset[i], in: hourlyW.time) {
                    let hi  = hourlyW.cloudcover_high[idx]
                    let mi  = hourlyW.cloudcover_mid[idx]
                    let lo  = hourlyW.cloudcover_low[idx]
                    sc = Int(((hi + mi + lo)/3.0).clamped(to: 0...100))
                } else {
                    sc = max(0, 100 - Int(daily.cloudcover_mean[i]))
                }
                list.append(DailyForecast(id: d, weekday: wd, score: sc))
            }

            // Extract today's details
            let sunFmt = DateFormatter()
            sunFmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
            if let sunD = sunFmt.date(from: daily.sunset[0]) {
                sunsetMoment = sunD
                goldenMoment = sunD.addingTimeInterval(-1800)
            }
            todayCloudMean = daily.cloudcover_mean[0]
            if let idx = indexFor(daily.sunset[0], in: hourlyW.time) {
                todayHighCloud = hourlyW.cloudcover_high[idx]
                todayRh        = hourlyW.relativehumidity_2m[idx]
                todayAod       = hourlyAir.aerosol_optical_depth[idx]
            }

            await MainActor.run {
                forecasts = list
                print("[Data] built \(list.count) days")
            }

        } catch {
            print("[Data] error:", error)
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func indexFor(_ isoSun: String, in hours: [String]) -> Int? {
        let p = isoSun.split(separator: "T")
        guard p.count == 2 else { return nil }
        let prefix = "\(p[0])T\(p[1].split(separator: ":")[0]):"
        return hours.firstIndex { $0.hasPrefix(prefix) }
    }

    // MARK: – Labels

    private func labelCloudMean(_ v: Double) -> String {
        v < 20   ? "Clear" :
        v < 60   ? "Partly" :
                  "Overcast"
    }
    private func labelHighCloud(_ v: Double) -> String {
        v < 10   ? "None" :
        v < 40   ? "Few" :
                  "Many"
    }
    private func labelHumidity(_ v: Double) -> String {
        v < 30   ? "Dry" :
        v < 70   ? "OK" :
                  "Humid"
    }
    private func labelAOD(_ v: Double) -> String {
        v < 0.1  ? "Low" :
        v < 0.3  ? "Mod" :
                  "High"
    }
}

// MARK: – Hex Color Extension

extension Color {
    /// Initialize a SwiftUI Color from a hex string like "#RRGGBB"
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let r, g, b: UInt64
        if hexClean.count == 6 {
            r = (int >> 16) & 0xFF
            g = (int >> 8)  & 0xFF
            b = int & 0xFF
        } else {
            r = 1; g = 1; b = 1
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: – Clamp Helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
