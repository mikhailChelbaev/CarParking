//
//  Car.swift
//  CarParking
//
//  Created by Mikhail on 02.06.2020.
//  Copyright © 2020 Mikhail. All rights reserved.
//

import UIKit
import MapKit

class Car: NSObject, Codable {
    
    // статус машины
    enum Status: String, Codable {
        case parked, going, notParked
        
        mutating func next() {
            switch self {
            case .parked:
                self = .going
            case .going:
                self = .notParked
            case .notParked:
                self = .parked
            }
        }
        
        func getButtonTitle() -> String {
            switch self {
            case .parked:
                return "Show route"
            case .going:
                return "Remove parking location"
            case .notParked:
                return "Park my car"
            }
        }
    }
    
    // местоположение
    struct Location: Codable {
        var lat: Double
        var lng: Double
        
        func converted() -> CLLocationCoordinate2D {
            return .init(latitude: lat, longitude: lng)
        }
    }
    
    // поля
    var status: Status
    var location: Location
    
    init(status: Status, lat: Double, lng: Double) {
        self.status = status
        self.location = Location(lat: lat, lng: lng)
    }
}

// наследуем MKAnnotation, чтобы отображать в виде маркера
extension Car: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        return location.converted()
    }
    
    var title: String? {
        return ""
    }

    var subtitle: String? {
        return ""
    }
}
