// SunsetForecast/Views/LocationDetailView.swift

import SwiftUI

struct LocationDetailView: View {
    let location: Location
    @State private var forecast: ForecastResponse?
    @State private var loadError: Error?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1a1a1a"),
                    Color(hex: "#2d2d2d")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Location header
                    VStack(spacing: 8) {
                        Text(location.displayName)
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .padding()

                    // Today's sunset card
                    if let f = forecast,
                       let rawSun = f.daily.sunset.first,
                       // API returns "YYYY-MM-DDTHH:MM", ISO8601DateFormatter wants seconds
                       let date = ISO8601DateFormatter().date(from: rawSun + ":00")
                    {
                        VStack(spacing: 12) {
                            Text("Sunset Today")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(date.formatted(.dateTime.hour().minute()))
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }

                    // Loading and error states
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding()
                    }
                    if let err = loadError {
                        Text(err.localizedDescription)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadForecast()
        }
    }

    private func loadForecast() async {
        isLoading = true
        defer { isLoading = false }

        do {
            forecast = try await SunsetService.shared.fetchData(
                for: Date(),
                lat: location.latitude,
                lon: location.longitude
            )
            print("[LocationDetail] fetched forecast for \(location.displayName)")
        } catch {
            loadError = error
            print("[LocationDetail] error fetching:", error)
        }
    }
}

#Preview {
    NavigationStack {
        LocationDetailView(
            location: Location(
                id: "0",
                name: "Sample City",
                latitude: 0,
                longitude: 0,
                country: "",
                admin1: nil,
                timeZoneIdentifier: TimeZone.current.identifier
            )
        )
        .environmentObject(FavoritesStore())  // if your detail view needs it elsewhere
    }
}
