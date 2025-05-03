// SunsetForecast/Views/SearchView.swift

import SwiftUI
import CoreLocation

struct SearchView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Sunsets")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top)

                // MARK: – Search Field
                TextField("Search cities…", text: $vm.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChange(of: vm.searchText) { new in
                        vm.updateSearch(text: new)
                    }

                // MARK: – Suggestions List
                List(vm.suggestions, id: \.self) { sug in
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
                                    .foregroundColor(.primary)
                                Text(localTime(for: sug))
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
        var fmt = DateFormatter()
        fmt.timeStyle = .short
        if let tz = loc.timeZone {
            fmt.timeZone = tz
        }
        return fmt.string(from: Date())
    }
}
