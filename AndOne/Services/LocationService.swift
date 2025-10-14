//
//  LocationService.swift
//  AndOne
//
//  Created by Bridges-Mobile-dev-s01 on 14/10/2025.
//

import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestWhenInUse() { manager.requestWhenInUseAuthorization() }
    func start() { manager.startUpdatingLocation() }
    func stop() { manager.stopUpdatingLocation() }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
}
