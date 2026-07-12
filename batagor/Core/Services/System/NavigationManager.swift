//
//  NavigationManager.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 30/10/25.
//

import Foundation
import SwiftUI

enum AppDestination: Hashable {
    case camera
    case gallery
}

@MainActor
class NavigationManager: ObservableObject {
    @Published var selectedTab: AppDestination = .gallery
    @Published var selectedMediaId: UUID?
    @Published var shouldShowDetail: Bool = false
    
    static let shared = NavigationManager()
    
    private init() {}
    
    func navigate(to destination: AppDestination) {
        print("Navigating to \(destination)")
        if destination != selectedTab {
            resetDetailNavigation()
        }
        selectedTab = destination
    }
    
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
