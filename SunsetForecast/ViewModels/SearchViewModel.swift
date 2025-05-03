// SunsetForecast/ViewModels/SearchViewModel.swift

import Foundation
import Combine
import CoreLocation

@MainActor
final class SearchViewModel: ObservableObject {
    // MARK: – Published inputs & outputs
    @Published var searchText: String = ""
    @Published var suggestions: [Location] = []
    @Published var errorMessage: String?

    // MARK: – Privates
    private var debounceTask: Task<Void, Never>?
    private let searchService: any LocationSearchService
    private let geocoder = CLGeocoder()

    // MARK: – Init
    init(searchService: any LocationSearchService = OpenMeteoSearchService()) {
        self.searchService = searchService
    }

    // MARK: – Public
    /// Call from your TextField’s onChange
    func updateSearch(text: String) {
        searchText = text
        performSearch(for: text)
    }

    /// After the user taps a suggestion, call this to get a fully‐populated Location
    func selectLocation(_ sug: Location) async -> Location {
        let cl = CLLocation(latitude: sug.latitude, longitude: sug.longitude)
        let pm = try? await geocoder.reverseGeocodeLocation(cl).first
        let name    = pm?.locality ?? sug.name
        let admin1  = pm?.administrativeArea
        let country = pm?.country ?? sug.country
        let tzId    = pm?.timeZone?.identifier ?? TimeZone.current.identifier

        return Location(
            id: "\(sug.latitude),\(sug.longitude)",
            name: name,
            latitude: sug.latitude,
            longitude: sug.longitude,
            country: country,
            admin1: admin1,
            timeZoneIdentifier: tzId
        )
    }

    // MARK: – Private helpers
    private func performSearch(for text: String) {
        guard !text.isEmpty else {
            suggestions = []
            return
        }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                print("[SearchVM] 🔍 Searching for:", text)
                let results = try await self.searchService.search(text)
                await MainActor.run {
                    self.suggestions = results
                    self.errorMessage = nil
                }
                print("[SearchVM] ✅ Got \(results.count) results")
            } catch {
                print("[SearchVM] ⚠️ Error:", error)
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
