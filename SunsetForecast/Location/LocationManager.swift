// Location/LocationManager.swift

import Foundation
import Combine
import CoreLocation

final class LocationManager: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        print("[LocationManager] Requesting when-in-use authorization")
        manager.requestWhenInUseAuthorization()
        print("[LocationManager] Starting location updates")
        manager.startUpdatingLocation()
    }

    /// Call this to re-request permission & updates (e.g. on a button tap)
    func requestLocation() {
        print("[LocationManager] requestLocation() called — status:", manager.authorizationStatus.rawValue)
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        print("[LocationManager] Authorization changed to:", status.rawValue)
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else {
            print("[LocationManager] didUpdateLocations: no locations")
            return
        }
        print("[LocationManager] didUpdateLocations:", loc.coordinate)
        DispatchQueue.main.async {
            self.coordinate = loc.coordinate
        }
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        let ns = error as NSError
        print("[LocationManager] didFailWithError:", ns.domain, "code", ns.code, "-", ns.localizedDescription)
    }
}
