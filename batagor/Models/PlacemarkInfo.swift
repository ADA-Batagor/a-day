//
//  PlacemarkInfo.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 11/11/25.
//

import Foundation
import CoreLocation
import MapKit

struct PlacemarkInfo {
    var name: String?
    var thoroughfare: String?
    var locality: String?
    var subLocality: String?
    var administrativeArea: String?
    var postalCode: String?
    var country: String?
    var areasOfInterest: [String]?
    
    init(from placemark: CLPlacemark) {
        self.name = placemark.name
        self.thoroughfare = placemark.thoroughfare
        self.subLocality = placemark.subLocality
        self.locality = placemark.locality
        self.administrativeArea = placemark.administrativeArea
        self.postalCode = placemark.postalCode
        self.country = placemark.country
        self.areasOfInterest = placemark.areasOfInterest
    }
    
    init(from placemark: MKPlacemark) {
        self.name = placemark.name
        self.thoroughfare = placemark.thoroughfare
        self.locality = placemark.locality
        self.subLocality = placemark.subLocality
        self.administrativeArea = placemark.administrativeArea
        self.postalCode = placemark.postalCode
        self.country = placemark.country
        self.areasOfInterest = placemark.areasOfInterest
    }
    
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if let thoroughfare = thoroughfare {
            return thoroughfare
        }
        if let subLocality = subLocality {
            return subLocality
        }
        if let locality = locality {
            return locality
        }
        if let areas = areasOfInterest, !areas.isEmpty, let firstArea = areas.first {
            return firstArea
        }
        return "Unknown Location"
    }
}
