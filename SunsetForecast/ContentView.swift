import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var sunsetService: MockSunsetService

    @State private var sunsetTime: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

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

            VStack(spacing: 16) {
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.white)
                } else if isLoading {
                    Text("Loading…")
                        .foregroundColor(.white)
                } else if locationManager.coordinate == nil {
                    Text("Waiting for location…")
                        .foregroundColor(.white)
                } else if let time = sunsetTime {
                    Text("Sunset Time")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(time)
                        .font(.title)
                        .foregroundColor(.white)
                } else {
                    Text("No data")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .task {
            await loadSunset()
        }
    }

    private func loadSunset() async {
        isLoading = true
        defer { isLoading = false }

        guard let coord = locationManager.coordinate else { return }

        do {
            let response = try await sunsetService.fetchSunset(
                for: Date(),
                lat: coord.latitude,
                lon: coord.longitude
            )
            if let iso = response.daily.first?.sunset,
               let date = ISO8601DateFormatter().date(from: iso) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                sunsetTime = formatter.string(from: date)
            } else {
                errorMessage = "Invalid sunset data"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MockSunsetService())
    }
}

// MARK: - Hex Color Extension

extension Color {
    /// Initialize a Color from a hex string, e.g. "#FF6B5C" or "FF6B5C"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17,
                            255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF,
                            255)
        case 8: // ARGB (32-bit)
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
