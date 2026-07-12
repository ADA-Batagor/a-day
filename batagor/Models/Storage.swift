//
//  PhotoModel.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 21/10/25.
//

import Foundation
import SwiftData
import CoreLocation

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
    
    var isExpired: Bool {
        return Date() > expiredAt
    }
    
    var isVideo: Bool {
        return mainPath.pathExtension.lowercased() == "mp4"
    }
    
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
