//
//  FlashCycle.swift
//  batagor
//
//  Created by Tude Maha on 12/07/2026.
//

import AVFoundation

enum FlashCycle: Int, CaseIterable {
    case off, auto, on
    
    mutating func next() {
        self = FlashCycle(rawValue: (rawValue + 1) % Self.allCases.count)!
    }
    
    var photoFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .auto: return .auto
        case .off: return .off
        case .on: return .on
        }
    }
    
    var torchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .auto: return .auto
        case .off: return .off
        case .on: return .on
        }
    }
    
    var torchOn: Bool {
        switch self {
        case .auto: return true
        case .off: return false
        case .on: return true
        }
    }
    
    var iconName: String {
        switch self {
        case .auto: return "bolt.badge.automatic.fill"
        case .on:   return "bolt.fill"
        case .off:  return "bolt.slash.fill"
        }
    }
    
    var toastName: String {
        switch self {
        case .auto: return "Flash Auto"
        case .off: return "Flash Off"
        case .on: return "Flash On"
        }
    }
}
