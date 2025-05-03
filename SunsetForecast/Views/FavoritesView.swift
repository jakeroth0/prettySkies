import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favStore: FavoritesStore
    @State private var showSearch = false

    var body: some View {
      NavigationStack {
        VStack {
          Button("Add new…") { showSearch = true }
            .padding()
          List(favStore.favorites, id: \.self) { loc in
            NavigationLink(loc.displayName) {
               LocationDetailView(location: loc)
            }
          }
        }
        .sheet(isPresented: $showSearch) {
          SearchView().environmentObject(favStore)
        }
      }
    }
}
