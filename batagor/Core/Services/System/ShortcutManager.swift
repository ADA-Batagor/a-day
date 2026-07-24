//
//  ShortcutManager.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 30/10/25.
//

import UIKit
import SwiftUI

@MainActor
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var shortcutItem: UIApplicationShortcutItem?
    
    private init() {}
    
    func handleShortcut(_ item: UIApplicationShortcutItem) {
        print("Handling shortcut: \(item.type)")
        self.shortcutItem = item
    }
    
    func processShortcutItem(navigationManager: NavigationManager) {
        guard let shortcut = shortcutItem else { return }
        
        if shortcut.type.contains("shortcutCamera") {
            print("Navigating shortcut: \(shortcut)")
            navigationManager.navigate(to: .camera)
        }
        
        shortcutItem = nil
    }
}
