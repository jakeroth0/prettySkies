import Foundation

/// Protocol for geocoding backends.
protocol LocationSearchService {
    func search(_ query: String) async throws -> [Location]
}
