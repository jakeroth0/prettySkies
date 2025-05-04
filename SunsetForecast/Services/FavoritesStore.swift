// SunsetForecast/Services/FavoritesStore.swift

import Foundation
import Combine

/// Holds your saved locations and persists them via UserDefaults
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [Location] = []
    
    // Maximum number of favorites allowed
    static let maxFavorites = 10

    private let key = "sunsetForecast_favorites"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        // Save whenever favorites change
        $favorites
          .dropFirst()
          .sink { [weak self] list in
            self?.save(list)
          }
          .store(in: &cancellables)
    }

    func add(_ loc: Location) {
        guard !favorites.contains(loc) else { return }
        guard favorites.count < Self.maxFavorites else { return }
        favorites.append(loc)
    }

    func remove(_ loc: Location) {
        favorites.removeAll { $0.id == loc.id }
    }
    
    func canAddMore() -> Bool {
        return favorites.count < Self.maxFavorites
    }
    
    func move(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
    }

    private func load() {
        guard
          let data = UserDefaults.standard.data(forKey: key),
          let decoded = try? JSONDecoder().decode(
            [Location].self,
            from: data
          )
        else { return }
        favorites = decoded
    }

    private func save(_ list: [Location]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
