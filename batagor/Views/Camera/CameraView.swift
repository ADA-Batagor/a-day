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
    
    @EnvironmentObject var timer: SharedTimerManager
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
                        VStack(spacing: 0) {
                            Spacer()
                            if let image = cameraViewModel.previewImage {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .overlay {
                                        if capturingPhoto {
                                            Color(.black)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(alignment: .topLeading) {
                                        if showFocusIndicator, let point = focusPoint {
                                            FocusIndicator()
                                                .offset(x: point.x - 35, y: point.y - 35)
                                        }
                                    }
                                    .padding(.horizontal, 22)
                                    .padding(.top, 12)
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
                            }
                            
                            if cameraViewModel.camera.isRunning && !cameraViewModel.camera.isPreviewPaused {
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigationManager.resetDetailNavigation()
                        navigationManager.navigate(to: .gallery)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.spaceGroteskSemiBold(size: 17))
                            .foregroundStyle(Color.lightBase)
                    }
                    .padding(.leading, 8)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    GalleryCount(currentCount: storages.count, foregroundColor: Color.lightBase, countOnly: true)
                }
            }
            .ignoresSafeArea(.all)
        }
        .task {
            await cameraViewModel.camera.start()
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
    
    struct FocusIndicator: View {
        @State private var scale: CGFloat = 1.2
        
        var body: some View {
            Rectangle()
                .stroke(Color.yellow, lineWidth: 2)
                .frame(width: 70, height: 70)
                .scaleEffect(scale)
                .opacity(scale > 1.0 ? 0.0 : 1.0)
                .onAppear {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
        }
    }
}

#Preview {
    Camera()
        .environmentObject(SharedTimerManager.shared)
}
