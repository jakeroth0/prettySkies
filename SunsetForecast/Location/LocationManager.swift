import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
    }
    
    func currentCoordinate() async -> CLLocationCoordinate2D? {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        
        return await withCheckedContinuation { continuation in
            if let coordinate = coordinate {
                continuation.resume(returning: coordinate)
            } else {
                // Store the continuation to resume later when we get a location
                let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                    if let coordinate = self?.coordinate {
                        timer.invalidate()
                        continuation.resume(returning: coordinate)
                    }
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        DispatchQueue.main.async {
            self.coordinate = loc.coordinate
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didFailWithError error: Error) {
        print("Location error:", error)
    }
} 