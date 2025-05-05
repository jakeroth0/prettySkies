import SwiftUI
import CoreLocation

struct FullscreenFavoritesView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    
    // Index of current location being displayed
    @State private var currentIndex: Int
    
    // Track gesture state for swiping
    @State private var offset: CGFloat = 0
    @State private var isGestureActive = false
    
    // Initialize with a starting location and the favorites store
    init(initialLocation: Location, favoritesStore: FavoritesStore) {
        // Find the index of the initial location
        let index = favoritesStore.favorites.firstIndex(where: { $0.id == initialLocation.id }) ?? 0
        _currentIndex = State(initialValue: index)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient - using sunset colors
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
                
                // Main content
                VStack {
                    // Header with close button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) of \(favoritesStore.favorites.count)")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                    }
                    
                    // Location content with gesture
                    ZStack {
                        // Previous location (if exists)
                        if currentIndex > 0 {
                            locationView(for: favoritesStore.favorites[currentIndex - 1])
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.8)
                                .offset(x: -geometry.size.width + offset/3)
                                .opacity(offset > 0 ? offset/geometry.size.width : 0)
                        }
                        
                        // Current location
                        locationView(for: favoritesStore.favorites[currentIndex])
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.8)
                            .offset(x: offset)
                        
                        // Next location (if exists)
                        if currentIndex < favoritesStore.favorites.count - 1 {
                            locationView(for: favoritesStore.favorites[currentIndex + 1])
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.8)
                                .offset(x: geometry.size.width + offset/3)
                                .opacity(offset < 0 ? -offset/geometry.size.width : 0)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isGestureActive = true
                                offset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold = geometry.size.width * 0.3
                                withAnimation(.easeOut(duration: 0.3)) {
                                    if value.translation.width > threshold && currentIndex > 0 {
                                        // Swipe right - go to previous
                                        currentIndex -= 1
                                        offset = 0
                                    } else if value.translation.width < -threshold && currentIndex < favoritesStore.favorites.count - 1 {
                                        // Swipe left - go to next
                                        currentIndex += 1
                                        offset = 0
                                    } else {
                                        // Snap back
                                        offset = 0
                                    }
                                }
                                isGestureActive = false
                            }
                    )
                    
                    // Navigation dots
                    HStack(spacing: 8) {
                        ForEach(0..<favoritesStore.favorites.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Create the location view for a given location
    private func locationView(for location: Location) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Location header
                VStack(spacing: 4) {
                    Text(location.displayName)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    if let admin1 = location.admin1, !admin1.isEmpty {
                        Text(admin1)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Today's score and details would be here
                // This could use a similar view to LocationDetail or LocationPreview
                // For now we'll use a placeholder
                
                VStack {
                    Text("Sunset Score")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("87%")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundColor(.white)
                        
                    HStack(spacing: 16) {
                        Text("Golden 7:45PM")
                        Text("Sunset 8:15PM")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // Weather conditions
                VStack(spacing: 16) {
                    Text("Today's Conditions")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 24) {
                        conditionItem(icon: "cloud.fill", value: "Partly", title: "Clouds")
                        conditionItem(icon: "sun.max.fill", value: "High", title: "UV Index")
                        conditionItem(icon: "humidity.fill", value: "Moderate", title: "Humidity")
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // Helper view for condition items
    private func conditionItem(icon: String, value: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    let mockStore = FavoritesStore()
    // Add a sample location to the store
    mockStore.add(Location(
        id: "preview",
        name: "San Francisco",
        latitude: 37.7749,
        longitude: -122.4194,
        country: "US",
        admin1: "California",
        timeZoneIdentifier: "America/Los_Angeles"
    ))
    
    return FullscreenFavoritesView(
        initialLocation: mockStore.favorites[0],
        favoritesStore: mockStore
    )
    .environmentObject(mockStore)
} 