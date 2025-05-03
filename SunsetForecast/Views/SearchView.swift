// SunsetForecast/Views/SearchView.swift

import SwiftUI
import CoreLocation

struct SearchView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Sunsets")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    // MARK: – Search Field
                    TextField("Search cities…", text: $vm.searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    // MARK: – kick off a search any time the text changes
                    .task(id: vm.searchText) {
                        await vm.performSearch()
                    }

                    // MARK: – Loading / Error
                    if vm.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else if let error = vm.error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .padding()
                    }

                    // MARK: – Suggestions List
                    List(vm.searchResults, id: \.self) { sug in
                        Button {
                            Task {
                                let loc = await vm.selectLocation(sug)
                                favoritesStore.add(loc)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sug.displayName)
                                        .foregroundColor(.white)
                                    Text(localTime(for: sug))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func localTime(for loc: Location) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.timeZone  = loc.timeZone ?? .current
        return fmt.string(from: Date())
    }
}
