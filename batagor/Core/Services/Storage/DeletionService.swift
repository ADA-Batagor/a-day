//
//  PhotoDeletionService.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 21/10/25.
//

import Foundation
import SwiftData
import BackgroundTasks
import WidgetKit

/// Removes expired ``Storage`` records and their backing files.
///
/// Invoked either from a scheduled `BGAppRefreshTaskRequest` (``performCleanup(modelContext:)``,
/// via ``scheduleBackgroundCleanup()``) or directly from user-initiated deletes
/// (``manualDelete(modelContext:storage:)``). Both paths delete files before rows
/// and reload widget timelines afterward. See <doc:StorageAndDeletion>.
class DeletionService {
    static let shared = DeletionService()
    static let backgroundTaskIdentifier = Bundle.main.object(forInfoDictionaryKey: "MainAppBundleIdentifier") as! String

    /// Deletes every ``Storage`` row whose `expiredAt` has passed, along with its
    /// main and thumbnail files, then reloads widget timelines.
    @MainActor
    func performCleanup(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Storage>()
        
        guard let allFiles = try? modelContext.fetch(descriptor) else {
            return
        }
        
        let now = Date()
        let expiredFiles: [Storage] = allFiles.filter {
            $0.expiredAt < now
        }
        
        guard !expiredFiles.isEmpty else {
            return
        }
        
        for file in expiredFiles {
            StorageManager.shared.deleteFile(fileURL: file.mainPath)
            StorageManager.shared.deleteFile(fileURL: file.thumbnailPath)
            modelContext.delete(file)
            print("deleted")
        }
        
        try? modelContext.save()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Deletes a single ``Storage`` row and its files immediately (user-initiated
    /// delete), then reloads widget timelines.
    func manualDelete(modelContext: ModelContext, storage: Storage) {
        StorageManager.shared.deleteFile(fileURL: storage.mainPath)
        StorageManager.shared.deleteFile(fileURL: storage.thumbnailPath)
        modelContext.delete(storage)
        
        try? modelContext.save()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Submits a `BGAppRefreshTaskRequest` so the system runs ``performCleanup(modelContext:)``
    /// opportunistically in the background.
    func scheduleBackgroundCleanup() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 )
        
        try? BGTaskScheduler.shared.submit(request)
    }
}
