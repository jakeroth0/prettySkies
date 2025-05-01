// SunsetForecast/ViewModels/SearchViewModel.swift

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var suggestions: [Location] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: LocationSearchService
    private var cancellables = Set<AnyCancellable>()

    init(service: LocationSearchService) {
        self.service = service

        // Debounce typing, then trigger search
        $query
          .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
          .removeDuplicates()
          .sink { [weak self] q in
            Task {
                await self?.doSearch(q)
            }
          }
          .store(in: &cancellables)
    }

    private func doSearch(_ q: String) async {
        guard !q.isEmpty else {
            suggestions = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let results = try await service.search(q)
            suggestions = results
        } catch {
            errorMessage = error.localizedDescription
            suggestions = []
        }
    }
}
