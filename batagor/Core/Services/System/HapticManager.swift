//
//  HapticManager.swift
//  batagor
//
//  Created by Tude Maha on 24/10/2025.
//

import UIKit

/// Triggers `UIImpactFeedbackGenerator` haptics from a single shared instance.
final class HapticManager {
    static let shared = HapticManager()

    /// Plays an impact haptic of the given style, preparing the generator first.
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
