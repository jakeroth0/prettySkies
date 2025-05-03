// SunsetForecast/ViewModels/SearchViewModel.swift

import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Location] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let service: LocationSearchService

    init(service: LocationSearchService = OpenMeteoSearchService()) {
        self.service = service
    }

    /// Performs a geocoding query when `searchText` changes.
    /// No longer `private`, so your view can `await` it directly.
    func performSearch() async {
        // empty text -> clear results
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let results = try await service.search(searchText)
            searchResults = results
        } catch {
            self.error = error
            searchResults = []
        }
    }
}
