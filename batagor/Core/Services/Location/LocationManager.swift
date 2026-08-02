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

/// Wraps `CLLocationManager` and embeds captured coordinates into finished media.
///
/// Publishes the latest fix as ``currentLocation``; does not itself decide when a
/// coordinate gets attached to a `Storage` record — see <doc:LocationAndGeocoding>
/// for how ``CameraViewModel`` uses this alongside ``GeocodeManager``.
class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Requests when-in-use location authorization from the user.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    /// Returns a copy of `image` with `location` embedded as EXIF GPS metadata.
    /// Not currently called anywhere — photos store their coordinate on the
    /// `Storage` record instead (see <doc:LocationAndGeocoding>).
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
    
    /// Exports the movie at `url` with `location` embedded as QuickTime location
    /// metadata, replacing the original file in place. Used by
    /// `CameraViewModel.handleSaveMovie(context:)`.
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
        
        exportSession.metadata = [locationMetadata]
        
        if #available(iOS 18.0, *) {
            Task {
                do {
                    try await exportSession.export(to: tempURL, as: .mp4)
                    try? FileManager.default.removeItem(at: url)
                    try FileManager.default.moveItem(at: tempURL, to: url)
                } catch {
                    print("Export failed: \(error.localizedDescription)")
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
        } else {
            exportSession.outputURL = tempURL
            exportSession.outputFileType = .mp4
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
