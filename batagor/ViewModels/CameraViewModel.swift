//
//  CameraViewModel.swift
//  batagor
//
//  Created by Tude Maha on 22/10/2025.
//

import AVFoundation
import SwiftUI
import SwiftData
import WidgetKit
import CoreLocation

@MainActor
class CameraViewModel: ObservableObject {
    let PHOTO_EXPIRY_TIME = 24 * 60 * 60
    let VIDEO_EXPIRY_TIME = 24 * 60 * 60
    
    let camera = CameraManager()
    let storageManager = StorageManager.shared
    let orientationManager = OrientationManager.shared
    let locationManager = LocationManager()
    let geocodeManager = ReverseGeocodeManager()
    
    @Published var previewImage: Image?
    @Published var photoTaken: PhotoData?
    @Published var movieFileURL: URL?
    
    init() {
        locationManager.requestPermission()
        
        Task {
            await handleCameraPreview()
        }
        
        Task {
            await handleCameraPhoto()
        }
        
        Task {
            await handleCameraMovie()
        }
    }
    
    func handleCameraPreview() async {
        let imageStream = camera.previewStream
            .map { $0.image }
        
        for await image in imageStream {
            Task { @MainActor in
                previewImage = image
            }
        }
    }
    
    func handleCameraPhoto() async {
        let unpackedPhotoStream = camera.photoStream
            .compactMap { await self.unpackPhoto($0) }
        
        for await photoData in unpackedPhotoStream {
            
            Task { @MainActor in
                photoTaken = photoData
            }
        }
    }
    
    func handleCameraMovie() async {
        let fileUrlStream = camera.movieFileStream
        
        for await url in fileUrlStream {
            Task { @MainActor in
                movieFileURL = url
            }
        }
    }
    
    func handleSavePhoto(context: ModelContext) async {
        if let image = photoTaken {
            let photo = UIImage(data: image.imageData)!
            let mainPath = storageManager.savePhoto(photo)
            let thumbnailPath = storageManager.saveThumbnail(photo)
            
            if let mainPath = mainPath, let thumbnailPath = thumbnailPath {
                let storage = Storage(
                    createdAt: Date(),
                    expiredAt: TimeInterval(PHOTO_EXPIRY_TIME),
                    mainPath: mainPath,
                    thumbnailPath: thumbnailPath,
                    location: locationManager.currentLocation
                )
                
                await storeLocation(storage: storage)
                
                context.insert(storage)
                print("Added \(mainPath) with location: \(locationManager.currentLocation?.coordinate.latitude ?? 0), \(locationManager.currentLocation?.coordinate.longitude ?? 0)")
            }
            
            try? context.save()
            print("Photo saved!")
            
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        photoTaken = nil
    }
    
    func handleSaveMovie(context: ModelContext) async {
        if let movieURL = movieFileURL {
            locationManager.addLocationToVideo(at: movieURL, location: locationManager.currentLocation)
            let asset = AVURLAsset(url: movieURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            // create thumbnail for 1 second mark
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                if let thumbnailURL = storageManager.saveThumbnail(UIImage(cgImage: cgImage)) {
                    let storage = Storage(
                        createdAt: Date(),
                        expiredAt: TimeInterval(VIDEO_EXPIRY_TIME),
                        mainPath: movieURL,
                        thumbnailPath: thumbnailURL,
                        location: locationManager.currentLocation
                    )
                    
                    await storeLocation(storage: storage)
                    
                    context.insert(storage)
                    try? context.save()
                }
            } catch {
                print("Error: \(error)")
            }
            
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        movieFileURL = nil
    }
    
    private func unpackPhoto(_ photo: AVCapturePhoto) -> PhotoData? {
        guard let imageData = photo.fileDataRepresentation() else { return nil }
        
        guard let cgImage = photo.cgImageRepresentation(),
              let metadataOrientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
              let cgImageOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation)
        else { return nil }
        
        let imageOrientation = UIImage.Orientation(cgImageOrientation)
        let image = Image(uiImage: UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation))
        let photoDimentions = photo.resolvedSettings.photoDimensions
        let imageSize = (width: Int(photoDimentions.width), height: Int(photoDimentions.height))
        
        return PhotoData(image: image, imageData: imageData, imageSize: imageSize)
    }
    
    private func storeLocation(storage: Storage) async {
        if let location = locationManager.currentLocation {
            let coordinate = location.coordinate
            await geocodeManager.reverseGeocode(coordinate: coordinate)
            
            if let placemarkInfo = geocodeManager.placemarkInfo {
                storage.locationName = placemarkInfo.displayName
                storage.locationCity = placemarkInfo.locality
            }
            
            geocodeManager.reset()
        }
    }
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

fileprivate extension UIImage.Orientation {
    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

struct PhotoData {
    var image: Image
    var imageData: Data
    var imageSize: (width: Int, height: Int)
}

enum CameraMode {
    case photo, video
}

extension CameraMode {
    mutating func toggle() {
        if self == .photo {
            self = .video
        } else {
            self = .photo
        }
    }
}
