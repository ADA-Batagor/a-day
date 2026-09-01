//
//  PermissionStatusService.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 18/11/25.
//

import AVFoundation
import CoreLocation
import Photos

enum PermissionKind {
    case camera, microphone, photos, location
}

/// Binary + not-yet-prompted state per BAT-41. Photos uses `.addOnly` scope,
/// so there's no "Limited" state to represent.
enum PermissionState: String {
    case on = "On"
    case off = "Off"
    case notSet = "Not Set"
}

/// Reads current permission status without prompting the user.
enum PermissionStatusService {
    static func status(for kind: PermissionKind) -> PermissionState {
        switch kind {
        case .camera:
            return state(from: AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return state(from: AVCaptureDevice.authorizationStatus(for: .audio))
        case .photos:
            return state(from: PHPhotoLibrary.authorizationStatus(for: .addOnly))
        case .location:
            return state(from: CLLocationManager().authorizationStatus)
        }
    }

    private static func state(from status: AVAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorized: return .on
        case .denied, .restricted: return .off
        case .notDetermined: return .notSet
        @unknown default: return .notSet
        }
    }

    private static func state(from status: PHAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorized: return .on
        case .limited, .denied, .restricted: return .off
        case .notDetermined: return .notSet
        @unknown default: return .notSet
        }
    }

    private static func state(from status: CLAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .on
        case .denied, .restricted: return .off
        case .notDetermined: return .notSet
        @unknown default: return .notSet
        }
    }
}
