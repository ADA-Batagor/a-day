//
//  Vibration.swift
//  batagor
//
//  Created by Tude Maha on 24/10/2025.
//

import UIKit

final class HapticManager {
    static let shared = HapticManager()
    
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
