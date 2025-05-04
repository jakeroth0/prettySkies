import SwiftUI
import Combine

// Tab enum to track the selected tab
enum Tab {
    case home
    case map
    case favorites
}

// Tab view selection model to control selected tab from anywhere
class TabViewSelection: ObservableObject {
    static let shared = TabViewSelection()
    
    @Published var selectedTab: Tab = .home
}

struct BottomNavBar: View {
    @ObservedObject private var tabSelection = TabViewSelection.shared
    
    var onMapTap: () -> Void = {}
    var onLocationTap: () -> Void = {}
    var onFavoritesTap: () -> Void = {}

    var body: some View {
        HStack {
            Button {
                tabSelection.selectedTab = .map
                onMapTap()
            } label: {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(tabSelection.selectedTab == .map ? .white : .white.opacity(0.7))
            }
            Spacer()
            Button {
                tabSelection.selectedTab = .home
                onLocationTap()
            } label: {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(tabSelection.selectedTab == .home ? .white : .white.opacity(0.7))
            }
            Spacer()
            Button {
                tabSelection.selectedTab = .favorites
                onFavoritesTap()
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(tabSelection.selectedTab == .favorites ? .white : .white.opacity(0.7))
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