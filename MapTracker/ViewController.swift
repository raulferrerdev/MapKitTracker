//
//  ViewController.swift
//  MapTracker
//
//  Created by RaulF on 31/03/2020.
//  Copyright © 2020 ImTech. All rights reserved.
//

import UIKit
import MapKit
import FABButton

class ViewController: UIViewController {
    
    private let mapView = MKMapView(frame: .zero)
    private let locationManager = CLLocationManager()
    private let rangeInMeters: Double = 500
    private let pointer = UIImageView(image: UIImage(systemName: "mappin"))
    private let addressLabel = UILabel(frame: .zero)
    private let geoCoder = CLGeocoder()
    private let mapTypeButton = FABView(buttonImage: UIImage(named: "earth"))
    private let startButton = UIButton(frame: .zero)
    
    private var previousLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAddressLabel()
        layoutUI()
        configureMapTypeButton()
        configureStartButton()
        checkLocationServices()
    }
    
    
    private func configureMapTypeButton() {
        mapTypeButton.delegate = self

        mapTypeButton.addSecondaryButtonWith(image: UIImage(named: "map")!, labelTitle: "Standard", action: {
            self.mapView.mapType = .mutedStandard
        })
        
        mapTypeButton.addSecondaryButtonWith(image: UIImage(named: "satellite")!, labelTitle: "Satellite", action: {
            self.mapView.mapType = .satellite
        })
        
        mapTypeButton.addSecondaryButtonWith(image: UIImage(named: "hybrid")!, labelTitle: "Hybrid", action: {
            self.mapView.mapType = .hybrid
        })
        
        mapTypeButton.setFABButton()
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
    
    
    private func configureStartButton() {
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start", for: .normal)
        startButton.backgroundColor = .systemRed
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18.0, weight: .bold)
        startButton.layer.cornerRadius = 5.0
        startButton.clipsToBounds = true
        startButton.addTarget(self, action: #selector(drawRoutes), for: .touchUpInside)
    }

    
    private func layoutUI() {
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        pointer.translatesAutoresizingMaskIntoConstraints = false
        pointer.tintColor = .red
        
        view.addSubview(mapView)
        view.addSubview(mapTypeButton)
        view.addSubview(pointer)
        view.addSubview(addressLabel)
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            addressLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            addressLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            addressLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5),
            addressLabel.heightAnchor.constraint(equalToConstant: 40),

            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            mapTypeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),

            pointer.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -14.5),
            pointer.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            pointer.widthAnchor.constraint(equalToConstant: 27),
            pointer.heightAnchor.constraint(equalToConstant: 29),
            
            startButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            startButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            startButton.widthAnchor.constraint(equalToConstant: 100),
            startButton.heightAnchor.constraint(equalToConstant: 40)
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
    
    
    @objc func drawRoutes() {
        guard let request = createRequest() else { return }
        let directions = MKDirections(request: request)
        mapView.removeOverlays(mapView.overlays)

        directions.calculate { [unowned self] (response, error) in
            guard let response = response else { return }
            let routes = response.routes
            for route in routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    
    func createRequest() -> MKDirections.Request? {
        guard let coordinate = locationManager.location?.coordinate else { return nil }
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        let origin = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: origin)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
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
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .green
        renderer.lineWidth = 5
        return renderer
    }
}


extension ViewController: FABSecondaryButtonDelegate {
    func secondaryActionForButton(_ action: @escaping () -> ()) {
        action()
    }
}
