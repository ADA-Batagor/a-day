//
//  ModelContainerService.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 27/10/25.
//

import Foundation
import SwiftData

/// Owns the single SwiftData `ModelContainer`, backed by `batagor.sqlite` inside
/// the App Group container. Both the `batagor` app and `widgetExtension` open this
/// same container — that's what keeps the widget in sync with no extra sync code.
/// See <doc:StorageAndDeletion>.
class ModelContainerService {
    /// App Group identifier the shared container and media directories live under.
    static let appGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: "GroupAppBundleIdentifier") as! String

    static let shared: ModelContainer = {
        let schema = Schema([
            Storage.self
        ])
        
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Shared app group container not found")
        }
        
        let storeURL = appGroupURL.appendingPathComponent("batagor.sqlite")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        
        do {
            return try ModelContainer(for: schema, configurations:[modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
