import SwiftUI

struct SearchView: View {
    @StateObject var vm: SearchViewModel
    @EnvironmentObject var store: FavoritesStore
    @State private var selected: Location? = nil

    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search for a city...", text: $vm.query)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
            }
            .padding(8)
            .background(Color(.secondarySystemFill))
            .cornerRadius(8)
            .padding(.horizontal)

            // Suggestions
            if vm.isLoading {
                ProgressView().padding()
            } else if let err = vm.errorMessage {
                Text("Error: \(err)")
                  .foregroundColor(.red)
                  .padding()
            } else {
                List(vm.suggestions) { loc in
                    Button {
                        print("[SearchView] Selected", loc.name)
                        selected = loc
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loc.name)
                                    .font(.body)
                                // Preview placeholder (score & time)
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(.plain)
            }
        }
        // Full-screen detail for tapped location
        .sheet(item: $selected) { loc in
            LocationDetailView(location: loc) {
                store.add(loc)
                selected = nil
            } onCancel: {
                selected = nil
            }
        }
        .navigationTitle("Search")
    }
}
