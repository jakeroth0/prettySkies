import SwiftUI

struct SearchView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Title
                Text("Sunsets")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top)

                // Search field
                TextField("Search cities…", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChange(of: viewModel.searchText) { _ in
                        Task { await viewModel.performSearch() }
                    }

                // Suggestions list
                List(viewModel.searchResults, id: \.id) { suggestion in
                    Button {
                        favoritesStore.add(suggestion)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.displayName)
                                    .foregroundColor(.primary)
                                Text(localTime(for: suggestion))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.black.ignoresSafeArea())
        }
    }

    private func localTime(for loc: Location) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.timeZone = loc.timeZone ?? .autoupdatingCurrent
        return fmt.string(from: Date())
    }
}

#Preview {
    NavigationStack {
        SearchView()
            .environmentObject(FavoritesStore())
    }
}
