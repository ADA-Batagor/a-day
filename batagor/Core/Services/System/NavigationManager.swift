//
//  NavigationManager.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 30/10/25.
//

import Foundation
import SwiftUI

/// The two top-level destinations ``NavigationManager`` can switch between.
enum AppDestination: Hashable {
    case camera
    case gallery
}

/// App-wide tab and detail-sheet navigation state.
///
/// Single shared instance so both in-app views and out-of-app entry points (the
/// widget's `OpenCameraIntent`, Home Screen shortcuts via ``ShortcutManager``) can
/// drive navigation the same way. See <doc:WidgetIntegration>.
@MainActor
class NavigationManager: ObservableObject {
    @Published var selectedTab: AppDestination = .gallery
    @Published var selectedMediaId: UUID?
    @Published var shouldShowDetail: Bool = false

    static let shared = NavigationManager()

    private init() {}

    /// Switches the active tab, resetting any open detail sheet if it changed.
    func navigate(to destination: AppDestination) {
        print("Navigating to \(destination)")
        if destination != selectedTab {
            resetDetailNavigation()
        }
        selectedTab = destination
    }
    
    /// Switches to the gallery tab and opens the detail sheet for `mediaId`.
    func navigateToMediaDetail(mediaId: UUID) {
        print("Navigating to media detail: \(mediaId)")
        
        selectedTab = .gallery
        selectedMediaId = mediaId
        shouldShowDetail = true
    }
    
    func resetDetailNavigation() {
        selectedMediaId = nil
        shouldShowDetail = false
    }
}
