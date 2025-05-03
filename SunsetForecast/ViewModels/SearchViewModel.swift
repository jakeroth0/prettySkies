import Foundation
import CoreLocation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText     = ""
    @Published var searchResults  = [Location]()
    @Published var isLoading      = false
    @Published var error: Error?

    private let service: LocationSearchService

    init(service: LocationSearchService = OpenMeteoSearchService()) {
        self.service = service
    }

    /// Called from your SearchView’s .onChange
    func updateSearch(text: String) {
        searchText = text
    }

    /// Actually performs the API call
    func performSearch() async {
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

    /// What happens when the user taps a suggestion.
    /// For now just returns the same Location, but you can
    /// reverse-geocode to refine tz/display-name here.
    func selectLocation(_ suggestion: Location) async -> Location {
        return suggestion
    }
}
