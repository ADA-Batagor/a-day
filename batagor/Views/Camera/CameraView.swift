//
//  Camera.swift
//  batagor
//
//  Created by Tude Maha on 22/10/2025.
//

import SwiftUI
import AVFoundation
import SwiftData

struct Camera: View {
    let MEDIA_LIMIT = 24
    
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var timer: TimerManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @Query var storages: [Storage]
    
    @State private var capturingPhoto = false
    @State private var currentDuration = 0.0
    @State private var isRecording = false
    @State private var storageCount = 0
    @State private var currentZoom: CGFloat = 1.0
    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false
    @State private var showStorageLimitAlert = false
    
    init() {
        _storages = Query(FetchDescriptor<Storage>())
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.rgb(red: 55, green: 64, blue: 83), location: 0.0),
                        Gradient.Stop(color: Color.darkBase, location: 1.0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                ZStack(alignment: .center) {
                    GeometryReader { geometry in
                        VStack(spacing: -2) {
                            HStack(alignment: .center) {
                                if #available(iOS 26, *) {
                                    Button {
                                        navigationManager.resetDetailNavigation()
                                        navigationManager.navigate(to: .gallery)
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.spaceGroteskSemiBold(size: 17))
                                            .foregroundStyle(Color.darkBase)
                                    }
                                    .padding(12)
                                    .glassEffect(
                                        .regular
                                            .tint(.batagorLight.opacity(0.5))
                                            .interactive(),
                                        in: .circle
                                    )
                                } else {
                                    Button {
                                        navigationManager.resetDetailNavigation()
                                        navigationManager.navigate(to: .gallery)
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.spaceGroteskSemiBold(size: 17))
                                            .foregroundStyle(Color.lightBase)
                                            .padding(.leading, 5)
                                    }
                                }
                                
                                Spacer()
                                GalleryCount(currentCount: storages.count, foregroundColor: Color.lightBase, countOnly: true)
                                    .padding(.trailing, 5)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 35)
                            
                            Spacer()
                            
                            if let image = cameraViewModel.previewImage {
                                ZStack(alignment: .topTrailing) {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .padding(.horizontal, 22)
                                        .padding(.top, 12)
                                        .overlay(alignment: .topLeading) {
                                            if showFocusIndicator, let point = focusPoint {
                                                FocusIndicator()
                                                    .offset(x: point.x - 35, y: point.y - 35)
                                            }
                                        }
                                        .overlay {
                                            if capturingPhoto {
                                                Color(.black)
                                            }
                                        }
                                        .overlay(alignment: .top) {
                                            if cameraViewModel.camera.flashMode == .auto {
                                                if #available(iOS 26, *) {
                                                    Text("Flash Auto")
                                                        .font(.spaceGroteskSemiBold(size: 16))
                                                        .foregroundStyle(
                                                            Color.adayDark
                                                        )
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .glassEffect(
                                                            .regular.tint(.adayLight.opacity(0.8)),
                                                            in: .capsule
                                                        )
                                                        .padding(.top, 20)
                                                } else {
                                                    Text("Flash Auto")
                                                        .font(.spaceGroteskSemiBold(size: 18))
                                                        .foregroundStyle(
                                                            Color.adayDark
                                                        )
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.adayLight.opacity(0.8))
                                                        .clipShape(.capsule)
                                                        .padding(.top, 20)
                                                }
                                            }
                                        }
                                        .gesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    let newZoom = currentZoom * value.magnitude
                                                    cameraViewModel.camera.setZoom(newZoom)
                                                }
                                                .onEnded { value in
                                                    currentZoom *= value.magnitude
                                                }
                                        )
                                        .simultaneousGesture(
                                            DragGesture(minimumDistance: 0)
                                                .onEnded { value in
                                                    let location = value.location
                                                    let normalizedX = location.x / geometry.size.width
                                                    let normalizedY = location.y / geometry.size.height
                                                    
                                                    let clampedPoint = CGPoint(
                                                        x: min(max(normalizedX, 0), 1),
                                                        y: min(max(normalizedY, 0), 1)
                                                    )
                                                    
                                                    focusPoint = location
                                                    withAnimation {
                                                        showFocusIndicator = true
                                                    }
                                                    
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                        withAnimation {
                                                            showFocusIndicator = false
                                                        }
                                                    }
                                                    cameraViewModel.camera.setFocus(at: clampedPoint)
                                                }
                                        )
                                    
                                    Button {
                                        cameraViewModel.camera.cycleFlash()
                                    } label: {
                                        Image(
                                            systemName: cameraViewModel.camera.flashMode.iconName
                                        )
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(
                                            cameraViewModel.camera.flashMode.rawValue == 2 ? Color.batagorSecondary : Color.batagorDark
                                                .opacity(0.5)
                                        )
                                        .clipShape(Circle())
                                    }
                                    .padding(.top, 15)
                                    .padding(.horizontal, 32)
                                }
                            } else {
                                ZStack {
                                    Color(.black)
                                    
                                    if cameraViewModel.showCameraPermissionAlert {
                                        FullScreenAlert(
                                            iconName: "camera",
                                            title: "Allow A Day to access your camera and microphone",
                                            message: "This lets you share photos, record videos and preview effects.",
                                            buttonText: "Open Settings",
                                            buttonActionURL: UIApplication.openSettingsURLString
                                        )
                                    }
                                }
                                .aspectRatio(9/16, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal, 22)
                            }
                            CameraToolbar(
                                cameraViewModel: cameraViewModel,
                                storageCount: storages.count,
                                latestStorage: storages.last,
                                currentDuration: $currentDuration,
                                isRecording: $isRecording,
                                capturingPhoto: $capturingPhoto
                            )
                            .containerRelativeFrame(.vertical) { height, _ in
                                height * 0.15
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30)
                        }
                        .safeAreaPadding(.top)
                        
                    }
                    if showStorageLimitAlert {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                            }
                        
                        CustomAlert(
                            title: "All spots are full",
                            message: "Delete an existing one or wait for a spot to open up.",
                            buttonTitle: "Accept",
                            onSubmit: {
                                showStorageLimitAlert = false
                                navigationManager.navigate(to: .gallery)
                            }
                        )
                    }
                    
                    
                }
                .onAppear {
                    cameraViewModel.camera.isPreviewPaused = false
                }
                .onDisappear {
                    cameraViewModel.camera.isPreviewPaused = true
                }
            }
            .ignoresSafeArea(.all)
        }
        .task {
            await cameraViewModel.startCamera()
        }
        .alert(
            "Microphone Access Required",
            isPresented: $cameraViewModel.showMicrophonePermissionAlert
        ) {
            Button("Open Settings") {
                if let settingsURL = URL(
                    string: UIApplication.openSettingsURLString
                ) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A Day needs microphone access to record audio in your videos. Please enable it in Settings.")
        }
        .alert(
            "Camera Interrupted",
            isPresented: $cameraViewModel.showInterruptionAlert
        ) {
            Button("OK", role: .cancel) {
                cameraViewModel.resetInterruption()
            }
        } message: {
            Text(cameraViewModel.cameraInterruptionMessage ?? "The camera session was interrupted.")
        }
        .onAppear {
            if storages.count >= MEDIA_LIMIT {
                showStorageLimitAlert = true
            }
        }
        .onDisappear {
            cameraViewModel.camera.stop()
        }
        .onChange(of: cameraViewModel.photoTaken?.imageData) {
            Task {
                await cameraViewModel.handleSavePhoto(context: modelContext)
            }
        }
        .onChange(of: cameraViewModel.movieFileURL) {
            Task {
                await cameraViewModel.handleSaveMovie(context: modelContext)
            }
        }
        .onChange(of: timer.currentTime) {
            if isRecording {
                withAnimation(.easeInOut(duration: 0.15)) {
                    currentDuration += 1
                }
            }
            
            Task { @MainActor in
                await DeletionService.shared.performCleanup(modelContext: modelContext)
            }
        }
        .onChange(of: storages.count) { oldValue, newValue in
            if newValue >= 24 && !showStorageLimitAlert {
                showStorageLimitAlert = true
            }
        }
    }
    
    struct PhotoButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

#Preview {
    Camera()
        .environmentObject(TimerManager.shared)
}
