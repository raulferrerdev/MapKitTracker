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
    private let rangeInMeters: Double = 500
    private let mapTypecontroller = UISegmentedControl(items: ["Standard", "Satellite", "Hybrid"])
    private let pointer = UIImageView(image: UIImage(systemName: "mappin"))
    private let addressLabel = UILabel(frame: .zero)
    private let geoCoder = CLGeocoder()
    
    private var previousLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAddressLabel()
        layoutUI()
        configureMapTypeController()
        checkLocationServices()
    }
    
    
    private func configureMapTypeController() {
        mapTypecontroller.selectedSegmentIndex = 0
        mapView.mapType = .standard
        mapTypecontroller.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
    }
    
    
    private func configureAddressLabel() {
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .systemFont(ofSize: 18.0, weight: .medium)
        addressLabel.textColor = .darkText
        addressLabel.textAlignment = .center
        addressLabel.backgroundColor = .init(white: 1, alpha: 0.75)
        addressLabel.layer.cornerRadius = 5.0
        addressLabel.clipsToBounds = true
    }
    
    
    @objc private func indexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            mapView.mapType = .mutedStandard
        case 1:
            mapView.mapType = .satellite
        case 2:
            mapView.mapType = .hybrid
        default:
            break
        }
    }

    
    private func layoutUI() {
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapTypecontroller.translatesAutoresizingMaskIntoConstraints = false
        pointer.translatesAutoresizingMaskIntoConstraints = false
        pointer.tintColor = .systemRed
        
        view.addSubview(mapView)
        view.addSubview(mapTypecontroller)
        view.addSubview(pointer)
        view.addSubview(addressLabel)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            addressLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            addressLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            addressLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5),
            addressLabel.heightAnchor.constraint(equalToConstant: 40),

            mapTypecontroller.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            mapTypecontroller.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mapTypecontroller.widthAnchor.constraint(equalToConstant: 300),
            
            pointer.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -14.5),
            pointer.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            pointer.widthAnchor.constraint(equalToConstant: 27),
            pointer.heightAnchor.constraint(equalToConstant: 29)
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
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.showsUserLocation = true
            centerViewOnUser()
            locationManager.startUpdatingLocation()
            previousLocation = getCenterLocation(for: mapView)
            break
        case .denied:
            // Here we must tell user how to turn on location on device
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Here we must tell user that the app is not authorize to use location services
            break
        @unknown default:
            break
        }
    }
    
    
    private func centerViewOnUser() {
        guard let location = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion.init(center: location,
                                                       latitudinalMeters: rangeInMeters,
                                                       longitudinalMeters: rangeInMeters)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let coordinates = mapView.centerCoordinate
        return CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}


extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorizationForLocation()
    }
}


extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        
        guard let previousLocation = self.previousLocation,
            center.distance(from: previousLocation) > 25 else { return }
        
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let _ = error { // Show alert for the user
                return
            }
            
            guard let placemark = placemarks?.first else { // Show alert for the user
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
}

