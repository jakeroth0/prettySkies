import SwiftUI

/// A card showing a 10-day forecast of sunset scores
struct ForecastCard: View {
    let forecasts: [SunsetForecast.DailyForecast]
    let title: String
    
    init(forecasts: [SunsetForecast.DailyForecast], title: String = "10-Day Forecast") {
        self.forecasts = forecasts
        self.title = title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "calendar")
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
} 