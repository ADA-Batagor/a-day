//
//  OrientationManager.swift
//  batagor
//
//  Created by Tude Maha on 10/11/2025.
//

import Foundation
import CoreMotion
import UIKit
import AVFoundation

class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var orientation: UIDeviceOrientation = .portrait
    @Published var rotation: Double = 0.0
    
    private let motionManager = CMMotionManager()
    
    init() {
        startUpdateMotion()
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func startUpdateMotion() {
        motionManager.deviceMotionUpdateInterval = 0.2
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let gravity = motion?.gravity else { return }
            
            let x = gravity.x
            let y = gravity.y
            
            var newOrientation: UIDeviceOrientation
            var newRotation: Double
            
            if fabs(y) >= fabs(x) {
                if y >= 0 {
                    newOrientation = .portraitUpsideDown
                    newRotation = 180
                } else {
                    newOrientation = .portrait
                    newRotation = 0
                }
            } else {
                if x >= 0 {
                    newOrientation = .landscapeRight
                    newRotation = -90
                } else {
                    newOrientation = .landscapeLeft
                    newRotation = 90
                }
            }
            
            if self.orientation != newOrientation {
                self.orientation = newOrientation
            }
            
            if self.rotation != newRotation {
                self.rotation = newRotation
            }
        }
    }
}
