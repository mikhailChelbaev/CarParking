//
//  MapViewController.swift
//  CarParking
//
//  Created by Mikhail on 02.06.2020.
//  Copyright © 2020 Mikhail. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    // MARK: - поля

    @IBOutlet weak var myLocation: UIButton!
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var controlButton: UIButton!
    
    private var currentLocation: CLLocation?
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        return manager
    }()
    
    private var showLocationAtFirst = true
    
    // MARK: - методы
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.startUpdatingLocation() // обновляем местоположение
        setUpMyLocationButton()
        map?.showsUserLocation = true
        map.delegate = self
        checkCarStatus()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setUpMyLocationButton()
    }
    
    // MARK: - обработчики кнопок

    @IBAction func showMyLocation(_ sender: Any) {
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func makeRouteOrSavePosition(_ sender: Any) {
        guard let coordinate = currentLocation?.coordinate else { return }
        
        let wrapper = UserDefaultsEncoded<Car>()
        var car = wrapper.getValue(for: "car")
        
        if car == nil {
            // паркуем первый раз
            car = Car(status: Car.Status.parked, lat: coordinate.latitude, lng: coordinate.longitude)
            // сохраняем изменения в UserDefaults
            wrapper.encode(key: "car", value: car!)
            addMarker(car: car!)
            return
        }
        
        switch car!.status {
        case .parked:
            // рисуем маршрут
            drawRoute(to: car!.location.converted())
        case .going:
            // пришли к машине, удаляем маркер и маршрут с карты
            map.removeAnnotations(map.annotations)
            map.removeOverlays(map.overlays)
        case .notParked:
            // паркуем машину
            car?.location.lat = coordinate.latitude
            car?.location.lng = coordinate.longitude
            addMarker(car: car!)
        }
        car?.status.next()
        controlButton.setTitle(car?.status.getButtonTitle(), for: .normal)
        
        // сохраняем изменения в UserDefaults
        wrapper.encode(key: "car", value: car!)
    }
    
    // MARK: - вспомогательные методы
    
    private func setUpMyLocationButton() {
        // рисует красивые тени
        myLocation.layer.shadowColor = UIColor.label.cgColor
        myLocation.layer.shadowOpacity = 0.1
        myLocation.layer.shadowRadius = 3
        myLocation.layer.shadowOffset = .init(width: 0, height: 1)
    }
    
    private func checkCarStatus() {
        let wrapper = UserDefaultsEncoded<Car>()
        if let car = wrapper.getValue(for: "car") {
            if car.status == .parked {
                addMarker(car: car)
            } else if car.status == .going {
                addMarker(car: car)
                car.status = .parked
                wrapper.encode(key: "car", value: car)
            }
            controlButton.setTitle(car.status.getButtonTitle(), for: .normal)
        }
    }
    
    private func drawRoute(to finish: CLLocationCoordinate2D) {
        let directionRequest = MKDirections.Request()
        
        // устанавливаем начало и конец
        directionRequest.source = .forCurrentLocation()
        directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: finish))
        directionRequest.transportType = .walking
        
        // считаем расстояние
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (routeResponse, routeError) in
            guard let routeResponse = routeResponse else {
                if let routeError = routeError {
                    print("Error: \(routeError)")
                }
                return
            }
            
            // рисуем маршрут
            let route = routeResponse.routes[0]
            self.map.addOverlay(route.polyline, level: .aboveRoads)
            let rect = route.polyline.boundingMapRect
            self.map.setRegion(MKCoordinateRegion(rect), animated: true)
        }
        
    }
    
    private func addMarker(car: Car) {
        map.addAnnotation(car)
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let _ = annotation as? Car {
            let view = MKMarkerAnnotationView()
            view.markerTintColor = .link
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .systemOrange
        renderer.lineWidth = 4
        return renderer
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        
        // сохраняем местоположение
        currentLocation = location
        
        if showLocationAtFirst {
            showPlaceOnMap(with: location.coordinate, animated: false)
        } else {
             showPlaceOnMap(with: location.coordinate)
        }
        showLocationAtFirst = false
        
        locationManager.stopUpdatingLocation()
    }
    
    func showPlaceOnMap(with location: CLLocationCoordinate2D, animated: Bool = true) {
        map.setRegion(MKCoordinateRegion(center: location, latitudinalMeters: 800, longitudinalMeters: 800), animated: animated)
    }
    
}

