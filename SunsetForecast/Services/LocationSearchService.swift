// SunsetForecast/Services/LocationSearchService.swift

import Foundation

protocol LocationSearchService {
    /// Returns up to 5 matching locations for the query string.
    func search(_ query: String) async throws -> [Location]
}

enum SearchError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}
