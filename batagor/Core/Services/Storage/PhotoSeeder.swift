//
//  PhotoSeeder.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 22/10/25.
//

import Foundation
import SwiftData
import UIKit

class PhotoSeeder {
    static let shared = PhotoSeeder()
    
    @MainActor
    func seed(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Storage>()
        if let existingPhotos = try? modelContext.fetch(descriptor), !existingPhotos.isEmpty {
            print("Photo already exists. Skipping...")
            return
        }
        
        print("Seeding sample photos...")
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen]
        let labels = ["Photo 1", "Photo 2", "Photo 3"]
        
        let expirationTimes: [TimeInterval] = [10, 30, 60]
        
        for (index, color) in colors.enumerated() {
            let dummyPhoto = createDummyPhoto(color: color, label: labels[index])
            
            if let fileURL = StorageManager.shared.savePhoto(dummyPhoto) {
                let file = Storage(createdAt: Date(), expiredAt: expirationTimes[index], mainPath: fileURL, thumbnailPath: fileURL)
                modelContext.insert(file)
//                print("Added \(labels[index]) - expires in \(expirationTimes[index])s")
            }
        }
        
        try? modelContext.save()
        print("Seeding completeed!")
    }
    
    private func createDummyPhoto(color: UIColor, label: String) -> UIImage {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let colors = [color.withAlphaComponent(0.8).cgColor, color.cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
                
            }
        }
        
        return image
    }
}
