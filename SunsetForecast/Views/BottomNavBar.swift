import SwiftUI
import Combine

// Tab enum to track the selected tab
enum Tab {
    case home
    case favorites
}

// Tab view selection model to control selected tab from anywhere
class TabViewSelection: ObservableObject {
    static let shared = TabViewSelection()
    
    @Published var selectedTab: Tab = .home
    @Published var homePageIndex: Int = 0
}

struct BottomNavBar: View {
    @ObservedObject private var tabSelection = TabViewSelection.shared
    
    var onLocationTap: () -> Void = {}
    var onFavoritesTap: () -> Void = {}
    
    // Total pages in TabView
    var totalPages: Int = 1
    
    var body: some View {
        ZStack {
            // Navigation buttons
            HStack {
                Button {
                    tabSelection.selectedTab = .home
                    onLocationTap()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(tabSelection.selectedTab == .home ? .white : .white.opacity(0.7))
                }
                .frame(width: 44)
                
                Spacer()
                
                // Page indicators
                if tabSelection.selectedTab == .home && totalPages > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == tabSelection.homePageIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: index == tabSelection.homePageIndex ? 8 : 6, height: index == tabSelection.homePageIndex ? 8 : 6)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                .animation(.spring(response: 0.3), value: tabSelection.homePageIndex)
                        }
                    }
                    .frame(minWidth: 100, alignment: .center)
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
                .frame(width: 44)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding(.bottom, 12)
            .padding(.horizontal, 8)
        }
    }
} 