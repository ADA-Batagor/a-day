# Camera Pipeline

How a frame goes from the camera sensor to a saved, expiring file.

## Overview

`CameraManager` (`Core/Services/Camera/`) is a thin wrapper around `AVFoundation`. It
owns the `AVCaptureSession` and exposes three `AsyncStream`s instead of delegate
callbacks, so `CameraViewModel` can consume them with `for await`:

- `previewStream: AsyncStream<CIImage>` — live viewfinder frames, produced in
  `AVCaptureVideoDataOutputSampleBufferDelegate.captureOutput(_:didOutput:from:)`.
- `photoStream: AsyncStream<AVCapturePhoto>` — one value per `takePhoto()` call,
  produced in `AVCapturePhotoCaptureDelegate.photoOutput(_:didFinishProcessingPhoto:error:)`.
- `movieFileStream: AsyncStream<URL>` — the finished movie file URL after
  `stopRecordingVideo()`, produced in
  `AVCaptureFileOutputRecordingDelegate.fileOutput(_:didFinishRecordingTo:from:error:)`.

`CameraViewModel.init()` starts three `Task`s (`handleCameraPreview`,
`handleCameraPhoto`, `handleCameraMovie`) that each drain one of these streams into a
`@Published` property (`previewImage`, `photoTaken`, `movieFileURL`) that
`CameraView` renders.

## Capture flow

```
CameraManager.start()
  └─ checkAuthorization() → configureCaptureSession() → captureSession.startRunning()

User taps shutter (photo)
  CameraViewModel → camera.takePhoto()
    → AVCapturePhotoOutput.capturePhoto(...)
    → photoOutput(_:didFinishProcessingPhoto:) → photoStream yields AVCapturePhoto
    → CameraViewModel.unpackPhoto(_:) decodes it into PhotoData
    → photoTaken is published → CameraView shows a review screen
    → handleSavePhoto(context:) writes it to disk + SwiftData (see StorageAndDeletion)

User holds shutter (video)
  CameraViewModel → camera.startRecordingVideo() / stopRecordingVideo()
    → movieFileOutput writes directly to the App Group container
    → fileOutput(_:didFinishRecordingTo:) → movieFileStream yields the URL
    → handleSaveMovie(context:) generates a thumbnail + writes to SwiftData
```

## Rotation and device switching

`CameraManager` tracks device orientation itself via `AVCaptureDevice.RotationCoordinator`
(`setupRotationCoordinator()`), independent of `OrientationManager` (which drives UI
rotation via `CoreMotion`). `switchCaptureDevices()` cycles between the first
available back and front camera; `updateSessionForCaptureDevice(_:)` reconfigures the
session's input without tearing down outputs.

## Location tagging

Photos and videos are geotagged differently. For photos, `CameraViewModel` stores the
captured coordinate directly on the `Storage` record (`latitude`/`longitude`/
`altitude`) rather than embedding it in the image file — `LocationManager` does have
an `addLocationToImage(_:location:)` helper for EXIF embedding, but nothing currently
calls it. For videos, `handleSaveMovie(context:)` calls
`LocationManager.addLocationToVideo(at:location:)`, which embeds the coordinate as
QuickTime location metadata directly into the exported movie file. Both photo and
video saves also reverse-geocode the coordinate into a human-readable place name —
see <doc:LocationAndGeocoding>.
