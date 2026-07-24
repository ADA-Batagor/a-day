//
//  batagorApp.swift
//  batagor
//
//  Created by Tude Maha on 21/10/2025.
//

import SwiftUI
import SwiftData

@main
struct batagorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var sharedTaskManager = TimerManager.shared
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    private var sharedModelContainer = ModelContainerService.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    switch navigationManager.selectedTab {
                    case .camera:
                        Camera()
                    case .gallery:
                        GalleryView()
                    }
                }
                .onAppear {
                    Task { @MainActor in
                        await DeletionService.shared.performCleanup(modelContext: sharedModelContainer.mainContext)
                        shortcutManager.processShortcutItem(navigationManager: navigationManager)
                        
                        if navigationManager.shouldShowDetail {
                             try? await Task.sleep(nanoseconds: 100_000_000)
                        }
                    }
                    sign()
                }
                .onChange(of: shortcutManager.shortcutItem, { oldValue, newValue in
                    if newValue != nil {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            shortcutManager.processShortcutItem(navigationManager: navigationManager)
                        }
                    }
                })
                .environmentObject(sharedTaskManager)
                .environmentObject(navigationManager)
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
        .modelContainer(sharedModelContainer)
        .backgroundTask(.appRefresh(DeletionService.backgroundTaskIdentifier)) { @MainActor in
            await DeletionService.shared.performCleanup(modelContext: sharedModelContainer.mainContext)
            DeletionService.shared.scheduleBackgroundCleanup()
        }
        .handlesExternalEvents(matching: [])
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "batagor" else { return }
        
        if url.host == "gallery" {
            print("Deep link: navigating to gallery")
            navigationManager.navigate(to: .gallery)
        } else if url.host == "camera" {
            print("Deep link: navigating to camera")
            navigationManager.navigate(to: .camera)
        } else if url.host == "media" {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let uuidString = pathComponents.first,
               let mediaId = UUID(uuidString: uuidString) {
                print("Deep link: navigating to media detail \(mediaId)")
                navigationManager.navigateToMediaDetail(mediaId: mediaId)
            }
        }
    }

    private func sign() {
        let batagor = """
        
        █▀▀▄ █▀▀█ ▀▀█▀▀ █▀▀█ █▀▀▀ █▀▀█ █▀▀█ 
        █▀▀▄ █▄▄█   █   █▄▄█ █ ▀█ █  █ █▄▄▀ 
        ▀▀▀  ▀  ▀   ▀   ▀  ▀ ▀▀▀▀ ▀▀▀▀ ▀ ▀▀ 
        
        """
        print(batagor)
    }
    
    private func checkWidgetIntent() {
        guard let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "GroupAppBundleIdentifier") as? String else {
            return
        }
        
        guard let sharedDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return
        }
        
        if sharedDefaults.bool(forKey: "isOpenCamera") {
            sharedDefaults.set(false, forKey: "isOpenCamera")
            navigationManager.navigate(to: .camera)
        }
    }
        
}
