import Foundation
import CoreLocation

/// Wraps CLLocationManager to publish the user’s coordinate.
final class LocationManager: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        print("[LocationManager] init: requesting when-in-use auth")
        manager.requestWhenInUseAuthorization()
    }

    /// Call to start / restart updates
    func requestLocation() {
        print("[LocationManager] requestLocation() status:",
              manager.authorizationStatus.rawValue)
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ m: CLLocationManager, didChangeAuthorization s: CLAuthorizationStatus) {
        print("[LocationManager] auth changed to", s.rawValue)
        if s == .authorizedWhenInUse || s == .authorizedAlways {
            m.startUpdatingLocation()
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.first else { return }
        let c = loc.coordinate
        print("[LocationManager] didUpdateLocations", c)
        DispatchQueue.main.async {
            self.coordinate = c
        }
        m.stopUpdatingLocation()  // one-shot
    }

    func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {
        print("[LocationManager] fail:", e.localizedDescription)
    }
}
