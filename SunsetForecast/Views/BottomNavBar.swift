import SwiftUI

struct BottomNavBar: View {
    var onMapTap: () -> Void = {}
    var onLocationTap: () -> Void = {}
    var onFavoritesTap: () -> Void = {}

    var body: some View {
        HStack {
            Button(action: onMapTap) {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: onLocationTap) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: onFavoritesTap) {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(.bottom, 12)
        .padding(.horizontal, 8)
    }
} 