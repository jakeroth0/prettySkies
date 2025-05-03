// SunsetForecast/Location/LocationManager.swift

import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var lastPlaceName: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        print("[LocationManager] init: requesting when-in-use auth")
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func requestLocation() {
        print("[LocationManager] requestLocation() status:", manager.authorizationStatus.rawValue)
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        print("[LocationManager] auth changed to", status.rawValue)
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        print("[LocationManager] didUpdateLocations", loc.coordinate)
        DispatchQueue.main.async {
            self.coordinate = loc.coordinate
        }
        // reverse-geocode to get a human name
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
            guard let p = placemarks?.first, error == nil else { return }
            let parts = [p.locality, p.administrativeArea, p.country]
                          .compactMap { $0 }
            DispatchQueue.main.async {
                self.lastPlaceName = parts.joined(separator: ", ")
                print("[LocationManager] lastPlaceName =", self.lastPlaceName!)
            }
        }
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        let ns = error as NSError
        print("[LocationManager] fail:", ns.localizedDescription)
    }
}
