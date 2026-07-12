//
//  LocationManager.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 11/11/25.
//

import Foundation
import CoreLocation
import ImageIO
import UIKit
import AVFoundation

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    func addLocationToImage(_ image: UIImage, location: CLLocation?) -> UIImage {
        guard let location = location,
              let imageData = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let uniformTypeIdentifier = CGImageSourceGetType(source) else {
            return image
        }
        
        let destinationData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(destinationData, uniformTypeIdentifier, 1, nil) else {
            return image
        }
        
        let gpsMetadata: [String: Any] = [
            kCGImagePropertyGPSLatitude as String: abs(location.coordinate.latitude),
            kCGImagePropertyGPSLatitudeRef as String: location.coordinate.latitude >= 0 ? "N" : "S",
            kCGImagePropertyGPSLongitude as String: abs(location.coordinate.longitude),
            kCGImagePropertyGPSLongitudeRef as String: location.coordinate.longitude >= 0 ? "E" : "W",
            kCGImagePropertyGPSAltitude as String: location.altitude,
            kCGImagePropertyGPSTimeStamp as String: ISO8601DateFormatter().string(from: location.timestamp),
            kCGImagePropertyGPSDateStamp as String: ISO8601DateFormatter().string(from: location.timestamp)
        ]
        
        var metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
        metadata[kCGImagePropertyGPSDictionary as String] = gpsMetadata
        
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        
        if CGImageDestinationFinalize(destination) {
            if let newImage = UIImage(data: destinationData as Data) {
                return newImage
            }
        }
        
        return image
    }
    
    func addLocationToVideo(at url: URL, location: CLLocation?) {
        guard let location = location else { return }
        
        let asset = AVURLAsset(url: url)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            return
        }
        
        let tempURL = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        let locationMetadata = AVMutableMetadataItem()
        locationMetadata.identifier = .quickTimeMetadataLocationISO6709
        locationMetadata.dataType = kCMMetadataBaseDataType_UTF8 as String
        
        let locationString = String(format: "%+09.5f%+010.5f/", location.coordinate.latitude, location.coordinate.longitude)
        locationMetadata.value = locationString as NSString
        
        exportSession.outputURL = tempURL
        exportSession.outputFileType = .mp4
        exportSession.metadata = [locationMetadata]
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.moveItem(at: tempURL, to: url)
                print("Location added to video")
            case .failed:
                print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
                try? FileManager.default.removeItem(at: tempURL)
            default:
                break
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
