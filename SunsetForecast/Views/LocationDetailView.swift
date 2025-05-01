import SwiftUI
import CoreLocation

struct LocationDetailView: View {
    let location: Location
    let onAdd: () -> Void
    let onCancel: () -> Void

    @Environment(\.presentationMode) private var pm
    @StateObject private var service = SunsetService()
    @State private var score: Int?
    @State private var sunsetTime: Date?
    @State private var goldenTime: Date?
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
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

                VStack(spacing: 24) {
                    // Location name
                    Text(location.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    // Score
                    if let sc = score {
                        Text("\(sc)%")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundColor(.white)
                    }

                    // Golden hour & sunset times
                    if let g = goldenTime, let s = sunsetTime {
                        HStack(spacing: 24) {
                            Text("Golden \(g.formatted(.dateTime.hour().minute()))")
                            Text("Sunset \(s.formatted(.dateTime.hour().minute()))")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("[Detail] Cancel")
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        print("[Detail] Add", location.name)
                        onAdd()
                    }
                }
            }
            .task {
                await loadToday()
            }
        }
    }

    private func loadToday() async {
        do {
            let resp = try await service.fetchData(
                for: Date(),
                lat: location.latitude,
                lon: location.longitude
            )
            let daily  = resp.daily
            let hourly = resp.hourlyWeather

            // Parse sunset time
            let sunFmt = DateFormatter()
            sunFmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
            if let iso = daily.sunset.first,
               let dt = sunFmt.date(from: iso) {
                sunsetTime = dt
                goldenTime = dt.addingTimeInterval(-1800)
            }

            // Compute score = average cloud cover at sunset, clamped 0–100
            if let iso = daily.sunset.first,
               let idx = indexFor(iso, in: hourly.time) {
                let hi  = hourly.cloudcover_high[idx]
                let mi  = hourly.cloudcover_mid[idx]
                let lo  = hourly.cloudcover_low[idx]
                let avg = (hi + mi + lo) / 3.0
                let clampedAvg = max(0, min(avg, 100))
                score = Int(clampedAvg)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[Detail] error:", error)
        }
    }

    private func indexFor(_ iso: String, in hours: [String]) -> Int? {
        let parts = iso.split(separator: "T")
        guard parts.count == 2 else { return nil }
        let prefix = "\(parts[0])T\(parts[1].split(separator: ":")[0]):"
        return hours.firstIndex { $0.hasPrefix(prefix) }
    }
}
