// SunsetForecast/Views/FavoritesView.swift

import SwiftUI
import MapKit

// MARK: – Completer wrapper for MKLocalSearchCompleter
private class CompleterDelegate: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    var queryFragment: String {
        get { completer.queryFragment }
        set { completer.queryFragment = newValue }
    }

    func completerDidUpdateResults(_ comp: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = comp.results
        }
    }

    func completer(_ comp: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("[Search] completer error:", error)
    }
}

struct FavoritesView: View {
    @EnvironmentObject var favoritesStore: FavoritesStore

    // — Search text and completer
    @State private var searchText = ""
    @StateObject private var completerDelegate = CompleterDelegate()

    // — Triggers the sheet when non-nil
    @State private var detailLocation: Location?

    var body: some View {
        List {
            // MARK: Search Results
            if !searchText.isEmpty {
                Section("Search Results") {
                    ForEach(completerDelegate.results, id: \.self) { suggestion in
                        Button {
                            lookup(suggestion)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // MARK: Favorites List
            Section("Favorites") {
                ForEach(favoritesStore.favorites) { loc in
                    NavigationLink(value: loc) {
                        Text(loc.name)
                    }
                }
            }
        }
        .navigationTitle("Favorites")

        // MARK: Search Bar
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search for a city or airport"
        )
        .onChange(of: searchText) { _, new in
            completerDelegate.queryFragment = new
        }

        // MARK: Detail Sheet for tapped suggestion
        .sheet(item: $detailLocation) { loc in
            NavigationStack {
                ContentView(fixedLocation: loc)
                    .environmentObject(favoritesStore)
                    .ignoresSafeArea()               // let gradient fill the screen
                    .presentationDetents([.large])   // full-height sheet
                    .onAppear {
                        print("[FavoritesView] showing detail for:", loc.name)
                    }
                    .toolbar {
                        // Cancel on the left
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                detailLocation = nil
                            }
                        }
                        // Add on the right
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                favoritesStore.add(loc)
                                detailLocation = nil
                            }
                        }
                    }
            }
        }

        // MARK: Tapping an existing favorite pushes into NavStack
        .navigationDestination(for: Location.self) { loc in
            ContentView(fixedLocation: loc)
                .environmentObject(favoritesStore)
        }
    }

    // MARK: lookup(...) → MKLocalSearch → Location
    private func lookup(_ suggestion: MKLocalSearchCompletion) {
        print("[FavoritesView] lookup suggestion:", suggestion.title)
        let request = MKLocalSearch.Request(completion: suggestion)
        MKLocalSearch(request: request).start { response, error in
            if let err = error {
                print("[Search] lookup error:", err)
                return
            }
            guard let item = response?.mapItems.first else {
                print("[Search] no map item")
                return
            }
            let parts = [
                item.name,
                item.placemark.locality,
                item.placemark.administrativeArea,
                item.placemark.country
            ].compactMap { $0 }
            let display = parts.joined(separator: ", ")
            let loc = Location(
                name: display,
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude
            )
            DispatchQueue.main.async {
                detailLocation = loc
            }
        }
    }
}
