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

class DeletionService {
    static let shared = DeletionService()
    static let backgroundTaskIdentifier = Bundle.main.object(forInfoDictionaryKey: "MainAppBundleIdentifier") as! String
    
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
    
    func manualDelete(modelContext: ModelContext, storage: Storage) {
        StorageManager.shared.deleteFile(fileURL: storage.mainPath)
        StorageManager.shared.deleteFile(fileURL: storage.thumbnailPath)
        modelContext.delete(storage)
        
        try? modelContext.save()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func scheduleBackgroundCleanup() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 )
        
        try? BGTaskScheduler.shared.submit(request)
    }
}
