//
//  FontManager.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 05/11/25.
//

import UIKit

struct FontManager {
    static func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear
        
        appearance.largeTitleTextAttributes = [.font: UIFont(name: "SpaceGrotesk-Bold", size: 34)!]
        
        appearance.titleTextAttributes = [.font: UIFont(name: "SpaceGrotesk-Bold", size: 17)!]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }
}
