//
//  PhotoStorageManager.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 21/10/25.
//

import Foundation
import UIKit

/// Reads and writes media files (photos, movies, thumbnails) inside the App Group
/// container shared with `widgetExtension`. See <doc:StorageAndDeletion>.
class StorageManager {
    static let shared = StorageManager()
    private let photosDirectory: URL
    private let moviesDirectory: URL
    private let thumbnailsDirectory: URL
    private let imageCache = NSCache<NSURL, UIImage>()

    private init() {
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ModelContainerService.appGroupIdentifier) else {
            fatalError("Shared container not found")
        }
        
        photosDirectory = sharedContainer.appendingPathComponent("Photos", isDirectory: true)
        moviesDirectory = sharedContainer.appendingPathComponent("Movies", isDirectory: true)
        thumbnailsDirectory = sharedContainer.appendingPathComponent("Thumbnails", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: moviesDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }
    
    /// Encodes `image` as HEIC and writes it into the shared Photos directory.
    func savePhoto(_ image: UIImage) -> URL? {
        let filename = "\(UUID().uuidString)"
        let fileURL = photosDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("heic")
        guard let data = image.heicData() else {
            return nil
        }
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    /// Encodes `image` as a compressed JPEG thumbnail into the shared directory.
    func saveThumbnail(_ image: UIImage) -> URL? {
        let filename = "\(UUID().uuidString)"
        let fileURL = thumbnailsDirectory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.3) else {
            print("jpg data error")
            return nil
        }
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("write error")
            return nil
        }
    }
    
    /// Loads the file at `fileURL` into a `UIImage`, or `nil` if it's missing/invalid.
    /// Cached in-memory so repeat loads of the same file (e.g. a gallery row
    /// re-rendering) skip the disk read and decode.
    func loadUIImage(fileURL: URL) -> UIImage? {
        let cacheKey = fileURL as NSURL
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else {
            return nil
        }

        imageCache.setObject(image, forKey: cacheKey)
        return image
    }
    
    /// Removes the file at `fileURL` from disk. Silently no-ops if it doesn't exist.
    func deleteFile(fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL)
        print("\(fileURL.absoluteString) deleted at \(Date())")
    }
}
