import SwiftUI

struct LocationDetailView: View {
  let location: Location
  @State private var data: ForecastResponse?
  @State private var isLoading = false
  private let svc = SunsetService.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Text(location.displayName).font(.title2)
        if isLoading { ProgressView() }
        else if let d = data {
          // … render your detailed UI …
          Text("Sunset: \(formatTime(d.daily.sunset[0]))")
        }
      }
    }
    .onAppear { Task { await load() } }
  }

  private func load() async {
    isLoading = true
    data = try? await svc.fetchData(
      for: Date(), lat: location.latitude, lon: location.longitude
    )
    isLoading = false
  }

  private func formatTime(_ s: String) -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm"
    guard let dt = f.date(from: s) else { return s }
    f.dateFormat = "h:mm a"
    return f.string(from: dt)
  }
}
