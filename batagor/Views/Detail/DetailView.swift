//
//  DetailView.swift
//  batagor
//
//  Created by Tude Maha on 30/10/2025.
//

import SwiftUI
import SwiftData
import AVKit
import UniformTypeIdentifiers

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedStorage: Storage?
    @Binding var showCover: Bool
    var previousPage: AppDestination = .gallery
    
    @State private var showToolbar: Bool = true
    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedThumbnail: Storage?
    @State private var selectedVideo: Storage?
    @State private var showSaveToast: Bool = false
    @State private var saveToastMessage: String = ""
    @State private var saveToastIcon: String = "checkmark.circle"
    @State private var showPhotoLibraryPermissionAlert: Bool = false
    
    //    gesture state
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var dismissOffset: CGSize = .zero
    @State private var dismissScale: CGFloat = 1.0
    @State private var isZoomed = false
    @State private var isShowedDetail = false
    @State private var blockHorizontal = false
    
    //    video player
    @State private var player: AVPlayer?
    
    @Query(sort: \Storage.createdAt)
    private var allStorages: [Storage]
    private var storages: [Storage] {
        allStorages.filter { $0.expiredAt > Date() }
    }
    
    @Namespace var toolbarNamespace
    
    private var toolbarIconFont: Font {
        if #available(iOS 26, *) {
            .spaceGroteskSemiBold(size: 18)
        } else {
            .spaceGroteskSemiBold(size: 22)
        }
    }
    
    private var toolbarSpacing: CGFloat? {
        if #available(iOS 26, *) { nil } else { 25 }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.rgb(red: 250, green: 244, blue: 230), location: 0.0),
                        Gradient.Stop(color: Color.rgb(red: 237, green: 243, blue: 254), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Button {
                            showCover = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.spaceGroteskSemiBold(size: 22))
                                .foregroundStyle(Color.darkBase)
                        }
                        .toolbarGlass()
                        
                        Spacer()
                        
                        if #available(iOS 26, *) {
                            GlassEffectContainer {
                                toolbarActions
                            }
                        } else {
                            toolbarActions
                        }
                    }
                    .padding(.top, 2)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(storages, id: \.self) { storage in
                                    VStack {
                                        if storage.mainPath.pathExtension == "mp4" {
                                            if selectedThumbnail == storage {
                                                VideoPlayer(player: player)
                                                    .frame(maxWidth: .infinity)
                                                    .overlay(alignment: .bottom) {
                                                        TimeRemainingBar(storage: storage, showText: false)
                                                    }
                                                    .clipShape(.rect(cornerRadius: 12))
                                                    .scaleEffect(scale * dismissScale)
                                                    .offset(CGSize(width: offset.width + dismissOffset.width, height: offset.height + dismissOffset.height))
                                                    .task {
                                                        player = AVPlayer(url: storage.mainPath as URL)
                                                        player?.play()
                                                    }
                                                    .onDisappear {
                                                        player?.pause()
                                                    }
                                            }
                                        } else {
                                            if let uiImage = StorageManager.shared.loadUIImage(fileURL: storage.mainPath) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .overlay(alignment: .bottom) {
                                                        TimeRemainingBar(storage: storage, showText: false)
                                                    }
                                                    .clipShape(.rect(cornerRadius: 12))
                                                    .scaleEffect(scale * dismissScale)
                                                    .offset(CGSize(width: offset.width + dismissOffset.width, height: offset.height + dismissOffset.height))
                                            }
                                        }
                                        
                                        if isShowedDetail {
                                            DetailInfoCard(storage: storage)
                                                .padding(.top, 10)
                                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                        }
                                        
                                    }
                                    .id(storage.id)
                                    .containerRelativeFrame(.horizontal)
                                    .frame(maxHeight: .infinity)
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(simultaneousGesture())
                                    .toast(isShowing: $showSaveToast, message: saveToastMessage, icon: saveToastIcon)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollDisabled(blockHorizontal)
                        .scrollPosition(id: $selectedThumbnail)
                        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                        .onAppear {
                            if let selectedStorage = selectedStorage {
                                selectedThumbnail = selectedStorage
                                proxy.scrollTo(selectedStorage.id)
                            }
                        }
                        .onChange(of: selectedStorage) { _, newValue in
                            if let new: Storage = newValue {
                                HapticManager.shared.impact(.light)
                                proxy.scrollTo(new.id)
                            }
                        }
                        .onChange(of: selectedVideo, { _, newValue in
                            if let _: Storage = newValue {
                                selectedThumbnail = selectedVideo
                            }
                        })
                        
                        .padding(.bottom, isShowedDetail ? 25 : 150)
                    }
                }
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.98
                }
                .padding(.horizontal, 35)
                .offset(y: geo.size.height * 0.07)
                
                if !isShowedDetail {
                    ZStack {
                        Knob()
                            .offset(y: geo.size.height * 0.9)
                        
                        CircularScrollView(
                            storages: storages,
                            selectedStorage: $selectedStorage,
                            selectedThumbnail: $selectedThumbnail,
                            selectedVideo: $selectedVideo,
                            geo: geo
                        )
                    }
                }
            }
            .ignoresSafeArea(.container)
        }
        .overlay(alignment: .bottom) {
            if let selectedStorage = selectedStorage {
                if #available(iOS 26, *) {
                    RemainingTime(storage: selectedStorage, variant: .large)
                        .padding(5)
                        .glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    RemainingTime(storage: selectedStorage, variant: .large)
                }
            }
        }
        .alert(
            "Photos Access Required",
            isPresented: $showPhotoLibraryPermissionAlert
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
            Text("A Day needs Photos access to save this snap. Please enable it in Settings.")
        }
    }
    
    private func simultaneousGesture() -> some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    if !isShowedDetail {
                        scale = lastScale * value
                    }
                }
                .onEnded { value in
                    if !isShowedDetail {
                        if scale < 1 {
                            withAnimation {
                                scale = 1
                                lastScale = 1
                                offset = .zero
                            }
                        } else if scale > 3 {
                            withAnimation {
                                scale = 3
                                lastScale = 3
                            }
                        }
                        
                        lastScale = scale
                        isZoomed = scale > 1
                    }
                },
            
            DragGesture()
                .onChanged { value in
                    if !isShowedDetail {
                        if !isZoomed {
                            if abs(value.translation.height) > abs(value.translation.width) {
                                blockHorizontal = true
                                if value.translation.height > abs(value.translation.width) {
                                    dismissOffset.height = value.translation.height
                                    let progress = min(abs(value.translation.height) / 200, 1.0)
                                    dismissScale = 1.0 - (progress * 0.5)
                                }
                            }
                        } else {
                            blockHorizontal = true
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                    } else {
                        if abs(value.translation.height) > abs(value.translation.width) {
                            blockHorizontal = true
                        }
                    }
                }
                .onEnded { value in
                    lastOffset = offset
                    
                    if !isShowedDetail {
                        if !isZoomed {
                            if value.translation.height > 150 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dismissOffset = CGSize(width: 0, height: value.translation.height > 0 ? 1000 : -1000)
                                    dismissScale = 0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showCover = false
                                }
                            } else if value.translation.height < -50 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isShowedDetail = true
                                }
                            } else {
                                withAnimation(.spring()) {
                                    dismissOffset = .zero
                                    dismissScale = 1.0
                                }
                            }
                        }
                    } else {
                        if value.translation.height > value.translation.width &&
                            value.translation.height > 50 {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isShowedDetail = false
                            }
                        }
                    }
                    
                    blockHorizontal = false
                }
        )
    }
    
    @ViewBuilder
    private var toolbarActions: some View {
        HStack(alignment: .center, spacing: toolbarSpacing) {
            if previousPage == .camera {
                if #available(iOS 26, *) {
                    Button {
                        showCover = false
                        NavigationManager.shared.navigate(to: .gallery)
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.spaceGroteskSemiBold(size: 17))
                            .foregroundStyle(Color.darkBase)
                    }
                    .toolbarGlass()
                } else {
                    Button {
                        showCover = false
                        NavigationManager.shared.navigate(to: .gallery)
                    } label: {
                        Text("All Media")
                            .font(.spaceGroteskSemiBold(size: 18))
                            .foregroundStyle(Color.darkBase)
                    }
                }
                
            }
            
            if let selectedStorage = selectedStorage {
                Button {
                    saveToPhotos(selectedStorage)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(toolbarIconFont)
                        .foregroundStyle(Color.darkBase)
                }
                .toolbarGlassUnion(toolbarNamespace)
                
                ShareLink(item: selectedStorage.mainPath) {
                    Image(systemName: "square.and.arrow.up")
                        .font(toolbarIconFont)
                        .foregroundStyle(Color.darkBase)
                }
                .toolbarGlassUnion(toolbarNamespace)
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(toolbarIconFont)
                        .foregroundStyle(Color.darkBase)
                }
                .toolbarGlassUnion(toolbarNamespace)
                .confirmationDialog(
                    "Don't need this snap anymore?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        DeletionService.shared
                            .manualDelete(
                                modelContext: modelContext,
                                storage: selectedStorage
                            )
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will delete it for good. This action can't be undone.")
                }
            }
        }
    }
    
    private func saveToPhotos(_ selectedStorage: Storage) {
        Task {
            do {
                try await PhotoLibraryService.shared.save(selectedStorage)
                saveToastIcon = "checkmark.circle"
                saveToastMessage = "Saved to Photos."
                showSaveToast = true
            } catch PhotoLibrarySaveError.permissionDenied {
                showPhotoLibraryPermissionAlert = true
            } catch {
                saveToastIcon = "exclamationmark.triangle"
                saveToastMessage = error.localizedDescription
                showSaveToast = true
            }
        }
    }
}

private struct GlassButtonIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .padding(10)
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
        }
    }
}

private struct GlassUnionButtonIfAvailable: ViewModifier {
    var namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(.glass)
                .glassEffectUnion(id: "toolbar", namespace: namespace)
        } else {
            content
        }
    }
}

private extension View {
    func toolbarGlass() -> some View {
        self.modifier(GlassButtonIfAvailable())
    }
    
    func toolbarGlassUnion(_ namespace: Namespace.ID) -> some View {
        self.modifier(GlassUnionButtonIfAvailable(namespace: namespace))
    }
}

#Preview {
    let image = UIImage(named: "sample")!
    let mainURL = StorageManager.shared.savePhoto(image)!
    let thumbnailURL = StorageManager.shared.saveThumbnail(image)!
    
    DetailView(selectedStorage: .constant(
        Storage(
            mainPath: mainURL,
            thumbnailPath: thumbnailURL
        )
    ), showCover: .constant(true))
    .environmentObject(TimerManager.shared)
}
