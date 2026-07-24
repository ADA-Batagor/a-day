//
//  PhotoModel.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 21/10/25.
//

import Foundation
import SwiftData
import CoreLocation

/// A single captured photo or video: its file locations, expiry, and optional
/// GPS/place data. The SwiftData `@Model` backing the shared store both `batagor`
/// and `widgetExtension` read from. See <doc:StorageAndDeletion>.
@Model
class Storage {
    var id: UUID
    var mainPath: URL
    var thumbnailPath: URL
    var createdAt: Date
    var expiredAt: Date
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var locationName: String?
    var locationCity: String?

    /// Whether `expiredAt` has passed — the condition `DeletionService` sweeps on.
    var isExpired: Bool {
        return Date() > expiredAt
    }

    /// Whether `mainPath` points at a video (`.mp4`) rather than a photo.
    var isVideo: Bool {
        return mainPath.pathExtension.lowercased() == "mp4"
    }

    /// Seconds until `expiredAt`, clamped to zero — what countdown UI displays.
    var timeRemaining: TimeInterval {
        max(0, expiredAt.timeIntervalSince(Date()))
    }
    
    // Default 24 hours
    init(createdAt: Date = Date(), mainPath: URL, thumbnailPath: URL, location: CLLocation? = nil) {
        self.id = UUID()
        self.createdAt = createdAt
        self.expiredAt = createdAt.addingTimeInterval(24 * 60 * 60)
        self.mainPath = mainPath
        self.thumbnailPath = thumbnailPath
        
        if let location = location {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.altitude = location.altitude
        }
    }
    
    // Custom expiration time
    init(createdAt: Date = Date(), expiredAt seconds: TimeInterval, mainPath: URL, thumbnailPath: URL, location: CLLocation? = nil) {
        self.id = UUID()
        self.createdAt = createdAt
        self.expiredAt = createdAt.addingTimeInterval(seconds)
        self.mainPath = mainPath
        self.thumbnailPath = thumbnailPath
        
        if let location = location {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.altitude = location.altitude
        }
    }
}
