// SunsetForecast/Views/SearchResultRow.swift

import SwiftUI

/// Displays a location search result with name, region, and country
struct SearchResultRow: View {
    let location: Location
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let admin1 = location.admin1, !admin1.isEmpty {
                    Text("\(admin1), \(location.country)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text(location.country)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
} 