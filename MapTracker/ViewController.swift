//
//  ViewController.swift
//  MapTracker
//
//  Created by RaulF on 31/03/2020.
//  Copyright © 2020 ImTech. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    private let mapView = MKMapView(frame: .zero)
    private let locationManager = CLLocationManager()
    private let rangeInMeters: Double = 10000


    override func viewDidLoad() {
        super.viewDidLoad()
                
        layoutUI()
        checkLocationServices()
    }

    
    private func layoutUI() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    
    private func checkLocationServices() {
        guard CLLocationManager.locationServicesEnabled() else {
            // Here we must tell user how to turn on location on device
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        checkAuthorizationForLocation()
    }
    
    
    private func checkAuthorizationForLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUser()
            locationManager.startUpdatingLocation()
            break
        case .denied:
            // Here we must tell user how to turn on location on device
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Here we must tell user that the app is not authorize to use location services
            break
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    
    private func centerViewOnUser() {
        if let location = locationManager.location?.coordinate {
            let coordinateRegion = MKCoordinateRegion.init(center: location,
                                                           latitudinalMeters: rangeInMeters,
                                                           longitudinalMeters: rangeInMeters)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
}


extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorizationForLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                             latitudinalMeters: rangeInMeters,
                                             longitudinalMeters: rangeInMeters)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

