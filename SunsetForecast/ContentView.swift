import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var sunset: Sunset?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                if let error = error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.white)
                } else if isLoading {
                    Text("Loading...")
                        .foregroundColor(.white)
                } else if locationManager.coordinate == nil {
                    Text("Waiting for location...")
                        .foregroundColor(.white)
                } else if let sunset = sunset {
                    VStack(spacing: 20) {
                        Text("Sunset Quality")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Text(sunset.quality)
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text("Time: \(sunset.time)")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            do {
                isLoading = true
                if let coordinate = await locationManager.currentCoordinate() {
                    sunset = try await SunsetService.fetchSunset(for: coordinate.latitude, longitude: coordinate.longitude)
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MockSunsetService())
}

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