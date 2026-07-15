//
//  CameraManager.swift
//  batagor
//
//  Created by Tude Maha on 22/10/2025.
//

import UIKit
import AVFoundation
import Combine

enum ADayPermissionStatus {
    case authorized, cameraDenied, microphoneDenied
}

class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
    //    create a new capture session from AVFoundation
    private let captureSession = AVCaptureSession()
    
    //    prepare input and output configuration
    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    //    prepare preview
    private var videoOutput: AVCaptureVideoDataOutput?
    private var sessionQueue: DispatchQueue!
    
    //    list capture devices
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [
            .builtInTrueDepthCamera,
            .builtInDualCamera,
//            .builtInDualWideCamera,
            .builtInWideAngleCamera,
        ], mediaType: .video, position: .unspecified).devices
    }
    
    private var allAudioDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        ).devices
    }
    
    private var availableAudioDevices: [AVCaptureDevice] {
        allAudioDevices
            .filter( {$0.isConnected} )
            .filter( {!$0.isSuspended} )
    }
    
    private var selectedAudioDevice: AVCaptureDevice?
    
//    flash mode init
    var flashMode: FlashCycle = .off
    
//    handle rotation
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var newRotationAngle: CGFloat = RotationAngle.portrait.rawValue
    
    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter { $0.position == .front }
    }
    
    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter { $0.position == .back }
    }
    
    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
        if let backDevice = backCaptureDevices.first {
            devices += [backDevice]
        }
        if let frontDevice = frontCaptureDevices.first {
            devices += [frontDevice]
        }
        return devices
    }
    
    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter( {$0.isConnected} )
            .filter( {!$0.isSuspended})
    }
    
    private var selectedCaptureDevice: AVCaptureDevice? {
        didSet {
            guard let selectedCaptureDevice = selectedCaptureDevice else { return }
            sessionQueue.async {
                self.updateSessionForCaptureDevice(selectedCaptureDevice)
            }
        }
    }
    
    //    capture session status
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    var isUsingFrontCaptureDevice: Bool {
        guard let selectedCaptureDevice = selectedCaptureDevice else { return false }
        return frontCaptureDevices.contains(selectedCaptureDevice)
    }
    
    var isUsingBackCaptureDevice: Bool {
        guard let selectedCaptureDevice = selectedCaptureDevice else { return false }
        return backCaptureDevices.contains(selectedCaptureDevice)
    }
    
    
    // capture photo
    private var addToPhotoStream: ((AVCapturePhoto) -> Void)?
    lazy var photoStream: AsyncStream<AVCapturePhoto> = {
        AsyncStream { continuation in
            addToPhotoStream = { photo in
                continuation.yield(photo)
            }
        }
    }()
    
    //    record movie
    private var addToMovieFileStream: ((URL) -> Void)?
    lazy var movieFileStream: AsyncStream<URL> = {
        AsyncStream { continuation in
            addToMovieFileStream = { fileURL in
                continuation.yield(fileURL)
            }
        }
    }()
    
    //    preview output
    var isPreviewPaused = false

    // MARK: - Interruption State

    @Published var isInterrupted = false
    @Published var interruptionMessage: String?
    @Published var isRecordingMovie = false

    private var cancellables = Set<AnyCancellable>()
    
    private var addToPreviewStream: ((CIImage) -> Void)?
    lazy var previewStream: AsyncStream<CIImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { ciImage in
                if !self.isPreviewPaused {
                    continuation.yield(ciImage)
                }
            }
        }
    }()
    
    func setupRotationCoordinator() {
        guard let videoDevice = self.selectedCaptureDevice, let previewLayer = self.previewLayer else {
            print("error setup rotation coordination")
            return
        }
        
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: videoDevice, previewLayer: previewLayer)
        
        rotationObservation = rotationCoordinator?.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _, change in
            
            guard let newAngle = change.newValue else {
                print("failed to get new angle value")
                return
            }
            
            DispatchQueue.main.async {
                self?.newRotationAngle = newAngle
            }
        }
    }
    
    // override init
    override init() {
        super.init()
        
        captureSession.sessionPreset = .low
        sessionQueue = DispatchQueue.init(label: Bundle.main.object(forInfoDictionaryKey: "MainAppBundleIdentifier") as! String)
        selectedCaptureDevice = availableCaptureDevices.first ?? AVCaptureDevice.default(for: .video)
        selectedAudioDevice = availableAudioDevices.first ?? AVCaptureDevice.default(for: .audio)
        observeInterruptions()
    }
    
    //    start capture session
    func start() async -> ADayPermissionStatus {
        let authorized = await checkAuthorization()
        guard authorized == .authorized else { return authorized }
        
        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async { [self] in
                    self.captureSession.startRunning()
                }
            }
            return .authorized
        }
        
        sessionQueue.async { [self] in
            self.configureCaptureSession { success in
                guard success else { return }
                self.captureSession.startRunning()
            }
        }
        
        return .authorized
    }
    
    //    stop capture session
    func stop() {
        guard isCaptureSessionConfigured else { return }
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    //    switch cameras
    func switchCaptureDevices() {
        if let selectedCaptureDevice = selectedCaptureDevice, let index = availableCaptureDevices.firstIndex(of: selectedCaptureDevice) {
            let nextIndex = (index + 1) % availableCaptureDevices.count
            self.selectedCaptureDevice = availableCaptureDevices[nextIndex]
        } else {
            self.selectedCaptureDevice = AVCaptureDevice.default(for: .video)
        }
    }
    
    // zoom camera
    func setZoom(_ factor: CGFloat) {
        guard let device = selectedCaptureDevice else { return }
        
        do {
            try device.lockForConfiguration()
            let clampedFactor = min(max(factor, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error.localizedDescription)")
        }
    }
    
    func setFocus(at point: CGPoint) {
        guard let device =  selectedCaptureDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting focus: \(error.localizedDescription)")
        }
    }
    
    //    flash mode cycle
    func cycleFlash() {
        flashMode.next()
    }
    
    // MARK: - Interruptions

    private func observeInterruptions() {
        NotificationCenter.default
            .publisher(
                for: AVCaptureSession.wasInterruptedNotification,
                object: captureSession
            )
            .sink { [weak self] notification in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isInterrupted = true
                }

                guard let userInfo = notification.userInfo,
                      let reasonValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int,
                      let reason = AVCaptureSession.InterruptionReason(rawValue: reasonValue) else {
                    return
                }

                switch reason {
                case .videoDeviceInUseByAnotherClient, .audioDeviceInUseByAnotherClient:
                    // Only surface the alert if the user was actively recording a movie.
                    // Photo capture stays silently disabled, matching native Camera app behaviour.
                    if self.isRecordingMovie {
                        DispatchQueue.main.async {
                            self.interruptionMessage = "Can't record while camera is in use by another app"
                        }
                    }
                case .videoDeviceNotAvailableInBackground,
                     .videoDeviceNotAvailableWithMultipleForegroundApps,
                     .videoDeviceNotAvailableDueToSystemPressure:
                    DispatchQueue.main.async {
                        self.interruptionMessage = "Camera unavailable"
                    }
                case .sensitiveContentMitigationActivated:
                    DispatchQueue.main.async {
                        self.interruptionMessage = "Camera unavailable due to sensitive content restrictions"
                    }
                @unknown default:
                    DispatchQueue.main.async {
                        self.interruptionMessage = "Camera session was interrupted"
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(
                for: AVCaptureSession.interruptionEndedNotification,
                object: captureSession
            )
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isInterrupted = false
                    self?.interruptionMessage = nil
                }
                self?.sessionQueue.async {
                    if self?.captureSession.isRunning == false {
                        self?.captureSession.startRunning()
                    }
                }
            }
            .store(in: &cancellables)
    }

    //    start record video
    func startRecordingVideo() {
        guard !isInterrupted else {
            DispatchQueue.main.async {
                self.interruptionMessage = "Can't record while camera is in use by another app"
            }
            return
        }

        let movieFileOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
            self.movieFileOutput = movieFileOutput
        }
        
        guard let movieFileOutput = self.movieFileOutput else {
            print("cannot find movie file output")
            return
        }
        
        applyTorch()
        
        if let movieFileOutputConnection = movieFileOutput.connection(with: .video) {
            movieFileOutputConnection.videoRotationAngle = self.newRotationAngle
        }
        
        guard let directoryPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ModelContainerService.appGroupIdentifier) else {
            print("cannot access local file domain")
            return
        }
        
        let filename = UUID().uuidString
        let filepath = directoryPath
            .appendingPathComponent("Movies", isDirectory: true)
            .appendingPathComponent(filename)
            .appendingPathExtension("mp4")
        
        movieFileOutput.startRecording(to: filepath, recordingDelegate: self)
    }
    
    //    stop record video
    func stopRecordingVideo() {
        guard let movieFileOutput = self.movieFileOutput else {
            print("cannot find movie file output")
            return
        }
        
        movieFileOutput.stopRecording()
        setTorch(false)
    }
    
    private func applyTorch() {
        switch self.flashMode {
        case .off:
            setTorch(false)
        case .auto:
            setTorch(true)
        case .on:
            setTorch(true)
        }
    }
    
    private func setTorch(_ on: Bool) {
        guard let device = selectedCaptureDevice, device.hasTorch, device.isTorchAvailable else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
    
    //    take photo
    func takePhoto() {
        guard let photoOutput = self.photoOutput else {
            print("cannot find photo output")
            return
        }
        
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            let isFlashAvailable = self.deviceInput?.device.isFlashAvailable ?? false
            if isFlashAvailable {
                photoSettings.flashMode = self.flashMode.photoFlashMode
            }
            
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            
            photoSettings.photoQualityPrioritization = .balanced
            
            if let photoOutputVideoConnection = photoOutput.connection(with: .video) {
                photoOutputVideoConnection.videoRotationAngle = self.newRotationAngle
            }
            
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    
    //    capture session configuration
    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        var success = false
        self.captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }
        
        let photoOutput = AVCapturePhotoOutput()
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: Bundle.main.object(forInfoDictionaryKey: "MainAppBundleIdentifier") as! String + ".output"))
        
        guard
            let selectedCaptureDevice = selectedCaptureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: selectedCaptureDevice)
        else {
            print("failed obtain video input")
            return
        }
        
        guard captureSession.canAddInput(deviceInput) else {
            print("can't add video device input to capture session")
            return
        }
        captureSession.addInput(deviceInput)
        self.deviceInput = deviceInput
        
        // do not fail the camera preview if microphone is being used by other apps
        if let selectedAudioDevice = selectedAudioDevice,
           let audioInput = try? AVCaptureDeviceInput(device: selectedAudioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
            self.audioInput = audioInput
        } else {
            print("Warning: Microphone input is currently unavailable and has been skipped.")
        }
        
        guard captureSession.canAddOutput(photoOutput) else {
            print("can't add photo output to capture session")
            return
        }
        guard captureSession.canAddOutput(videoOutput) else {
            print("can't add video output to capture session")
            return
        }
        
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        
        self.photoOutput = photoOutput
        self.videoOutput = videoOutput
        
        photoOutput.maxPhotoQualityPrioritization = .balanced
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setupRotationCoordinator()

        updateVideoOutputConnection()
        
        isCaptureSessionConfigured = true
        success = true
    }
    
    
    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        guard isCaptureSessionConfigured else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        
        if let deviceInput = deviceInputFor(device: captureDevice) {            
            if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setupRotationCoordinator()
        
        updateVideoOutputConnection()
    }
    
    //    video output configuration
    private func updateVideoOutputConnection() {
        if let videoOutput = videoOutput, let videoOutputConnection = videoOutput.connection(with: .video) {
            if videoOutputConnection.isVideoMirroringSupported {
                videoOutputConnection.isVideoMirrored = isUsingFrontCaptureDevice
            }
        }
    }
    
    private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            print("error get capture devide: \(error.localizedDescription)")
            return nil
        }
    }
    
    //    check autorization for camera access
    private func checkAuthorization() async -> ADayPermissionStatus {
        // check camera access
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .denied || cameraStatus == .restricted {
            return .cameraDenied
        }
        if cameraStatus == .notDetermined {
            sessionQueue.suspend()
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            if !granted { return .cameraDenied }
        }
        
        // check audio access
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .denied || audioStatus == .restricted {
            return .microphoneDenied
        }
        if audioStatus == .notDetermined {
            sessionQueue.suspend()
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            sessionQueue.resume()
            if !granted { return .microphoneDenied }
        }
        
        return .authorized
    }

    func resetInterruption() {
        DispatchQueue.main.async {
            self.isInterrupted = false
            self.interruptionMessage = nil
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let error = error {
            print("capture photo error: \(error.localizedDescription)")
        }
        
        addToPhotoStream?(photo)
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didStartRecordingTo fileURL: URL,
                    from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.isRecordingMovie = true
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: (any Error)?) {
        DispatchQueue.main.async {
            self.isRecordingMovie = false
        }
        
        var recordingSuccess = true
        if let error = error {
            print("file output error: \(error.localizedDescription)")
            
            let nsError = error as NSError
            if let successfullyFinished = nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool {
                recordingSuccess = successfullyFinished
            } else {
                recordingSuccess = false
            }
            
            if !recordingSuccess {
                DispatchQueue.main.async {
                    self.isInterrupted = true
                    if nsError.code == AVError.diskFull.rawValue {
                        self.interruptionMessage = "Cannot start recording, disk is full"
                    } else if nsError.code == AVError.sessionWasInterrupted.rawValue {
                        self.interruptionMessage = "Cannot start recording, camera is in use by another app"
                    } else {
                        self.interruptionMessage = "Cannot start recording, \(nsError.localizedDescription)"
                    }
                }
                
                // Clean up the file
                try? FileManager.default.removeItem(at: outputFileURL)
            }
        }
        
        if recordingSuccess {
            addToMovieFileStream?(outputFileURL)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        connection.videoRotationAngle = RotationAngle.portrait.rawValue
        addToPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
    }
}

private enum RotationAngle: CGFloat {
    case portrait = 90
    case portraitUpsideDown = 270
    case landscapeRight = 180
    case landscapeLeft = 0
}
