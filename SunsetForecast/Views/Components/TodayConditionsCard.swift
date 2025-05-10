import SwiftUI

/// A card showing today's weather conditions relevant to sunset quality
struct TodayConditionsCard: View {
    let cloudMean: Double?
    let cloudAtSun: Double?
    let humidity: Double?
    let aod: Double?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Conditions")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(), GridItem()]) {
                // Cloud Mean
                if let cm = cloudMean {
                    variableTile(icon: "cloud.fill",
                                 title: "Clouds (mean)",
                                 label: labelCloudMean(cm))
                } else {
                    variableTile(icon: "cloud.fill",
                                 title: "Clouds (mean)",
                                 label: "Loading...")
                }
                
                // Cloud at Sunset
                if let cu = cloudAtSun {
                    variableTile(icon: "cloud.sun.fill",
                                 title: "Cloud @ Sun",
                                 label: "\(Int(cu))%")
                } else {
                    variableTile(icon: "cloud.sun.fill",
                                 title: "Cloud @ Sun",
                                 label: "Loading...")
                }
                
                // Humidity
                if let hu = humidity {
                    variableTile(icon: "humidity.fill",
                                 title: "Humidity",
                                 label: labelHumidity(hu))
                } else {
                    variableTile(icon: "humidity.fill",
                                 title: "Humidity",
                                 label: "Loading...")
                }
                
                // AOD
                if let ao = aod {
                    variableTile(icon: "sun.haze.fill",
                                 title: "AOD",
                                 label: labelAOD(ao))
                } else {
                    variableTile(icon: "sun.haze.fill",
                                 title: "AOD",
                                 label: "Loading...")
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
    
    private func labelCloudMean(_ v: Double) -> String {
        v < 20 ? "Clear" :
        v < 60 ? "Partly" :
               "Overcast"
    }

    private func labelHumidity(_ v: Double) -> String {
        v < 40 ? "Dry" :
        v < 70 ? "OK" :
               "Humid"
    }

    private func labelAOD(_ v: Double) -> String {
        v < 0.1 ? "Low" :
        v < 0.3 ? "Mod" :
               "High"
    }
} 