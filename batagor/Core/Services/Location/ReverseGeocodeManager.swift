//
//  ReverseGeocodeManager.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 11/11/25.
//

import Foundation
import CoreLocation
import MapKit

@MainActor
class ReverseGeocodeManager: ObservableObject {
    @Published var placemarkInfo: PlacemarkInfo?
    @Published var isLoading: Bool = false
    
    private let maxSearchDistance: CLLocationDistance = 50
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }
        
        // Inconsistency accurate building location
        // await searchForBuilding(coordinate: coordinate)
        
        await geocodeWithCLGeocoder(coordinate: coordinate)
    }
    
    private func searchForBuilding(coordinate: CLLocationCoordinate2D) async {
        let searchTerms = [
            "restaurants",
            "shops",
            "coffee",
            "nearby places"
        ]
        for searchTerm in searchTerms {
            let request = MKLocalSearch.Request()
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            )
            request.resultTypes = [.pointOfInterest, .address, .physicalFeature]
            request.naturalLanguageQuery = searchTerm
            
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                
                if !response.mapItems.isEmpty {
                    let sortedItems = response.mapItems.sorted { item1, item2 in
                        let loc1 = item1.placemark.coordinate
                        let loc2 = item2.placemark.coordinate
                        let dist1 = distance(from: coordinate, to: loc1)
                        let dist2 = distance(from: coordinate, to: loc2)
                        return dist1 < dist2
                    }
                    
                    print("Found \(sortedItems.count) \(searchTerm)")
                    for (index, item) in sortedItems.prefix(5).enumerated() {
                        let dist = distance(from: coordinate, to: item.placemark.coordinate)
                        print("  \(index + 1). \(item.name ?? "Unknown") - \(Int(dist))m away")
                    }
                    
                    if let closest = sortedItems.first,
                       distance(from: coordinate, to: closest.placemark.coordinate) < maxSearchDistance {
                        if let name = closest.name, !name.isEmpty {
                            var tempInfo = PlacemarkInfo(from: closest.placemark)
                            tempInfo.name = name
                            placemarkInfo = tempInfo
                            print("Using POI: \(name)")
                        }
                    } else if let closest = sortedItems.first {
                        let dist = distance(from: coordinate, to: closest.placemark.coordinate)
                        print("Closest POI '\(closest.name ?? "Unknown")' is \(Int(dist))m away (limit: \(Int(maxSearchDistance))m)")
                    }
                }
            } catch {
                print("Local search error: \(error.localizedDescription)")
                continue
            }
        }
        
    }
    
    private func geocodeWithCLGeocoder(coordinate: CLLocationCoordinate2D) async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                var info = PlacemarkInfo(from: placemark)
                
                if let existingName = placemarkInfo?.name, !existingName.isEmpty {
                    info.name = existingName
                }
                
                placemarkInfo = info
                
//                print("Geocoder result:")
//                print("  Name: \(placemark.name ?? "nil")")
//                print("  Thoroughfare: \(placemark.thoroughfare ?? "nil")")
//                print("  SubLocality: \(placemark.subLocality ?? "nil")")
//                print("  Locality: \(placemark.locality ?? "nil")")
//                print("  AreasOfInterest: \(placemark.areasOfInterest?.joined(separator: ", ") ?? "nil")")
            }
        } catch {
            print("Reverse geocoding error: \(error.localizedDescription)")
        }
    }
    
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func reset() {
        placemarkInfo = nil
        isLoading = false
    }
}
