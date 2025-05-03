import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locMgr = LocationManager()
    private let svc = SunsetService.shared


    @State private var forecasts: [DailyForecast] = []
    @State private var locationName: String?
    @State private var isLoading = false
    @State private var errorMsg:   String?

    var body: some View {
        ZStack {
            LinearGradient(
              gradient: Gradient(colors: [.black, .gray]),
              startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    forecastList
                }
                .padding()
            }
        }
        .onAppear { locMgr.requestLocation() }
        .onReceive(locMgr.$coordinate) { coord in
            guard let c = coord else { return }
            Task { await loadForecast(for: c) }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("SunsetForecast")
               .font(.largeTitle.bold())
               .foregroundColor(.white)
            if let n = locationName {
               Text(n).foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var forecastList: some View {
        Group {
          if isLoading { ProgressView().tint(.white) }
          else if let err = errorMsg {
            Text(err).foregroundColor(.red)
          } else {
            ForEach(forecasts) { f in
              HStack {
                Text(f.weekday)
                Spacer()
                Text("\(f.score)%")
              }
              .padding().background(.ultraThinMaterial).cornerRadius(8)
            }
          }
        }
    }

    /// Small struct for our list
    struct DailyForecast: Identifiable {
      let id: Date; let weekday: String; let score: Int
    }

    private func loadForecast(for coord: CLLocationCoordinate2D) async {
        isLoading = true; errorMsg = nil
        await fetchLocationName(coord)
        do {
          let resp = try await svc.fetchData(
            for: Date(), lat: coord.latitude, lon: coord.longitude
          )
          buildForecasts(from: resp)
        } catch {
          errorMsg = error.localizedDescription
          print("[ContentView] load error:", error)
        }
        isLoading = false
    }

    private func fetchLocationName(_ c: CLLocationCoordinate2D) async {
        let loc = CLLocation(latitude: c.latitude, longitude: c.longitude)
        if let p = try? await CLGeocoder().reverseGeocodeLocation(loc).first {
            let parts = [p.locality, p.administrativeArea]
                .compactMap { $0 }.joined(separator: ", ")
            await MainActor.run { locationName = parts }
            print("[ContentView] name =", parts)
        }
    }

    private func buildForecasts(from r: ForecastResponse) {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var list: [DailyForecast] = []
        for i in r.daily.time.indices {
            guard let d = df.date(from: r.daily.time[i]) else { continue }
            let wd = d.formatted(.dateTime.weekday(.abbreviated))
            let sc = max(0, 100 - Int(r.daily.cloudcover_mean[i]))
            list.append(.init(id: d, weekday: wd, score: sc))
        }
        forecasts = list
        print("[ContentView] built", list.count, "items")
    }
}
