//
//  PhotoLibraryService.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import Foundation
import Photos

enum PhotoLibrarySaveError: LocalizedError {
    case permissionDenied, saveFailed(Error?)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photos access is needed to save this snap."
        case .saveFailed:
            return "Couldn't save this snap to Photos."
        }
    }
}

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    
    private init() {}
    
    func save(_ storage: Storage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoLibrarySaveError.permissionDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                if storage.isVideo {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: storage.mainPath)
                } else {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: storage.mainPath)
                }
            }
        } catch {
            throw PhotoLibrarySaveError.saveFailed(error)
        }
    }
}
