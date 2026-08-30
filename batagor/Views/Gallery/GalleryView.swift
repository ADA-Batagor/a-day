//
//  GalleryView.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 21/10/25.
//

import SwiftUI
import SwiftData

struct GalleryView: View {
    let MEDIA_LIMIT = 24

    @EnvironmentObject var timer: TimerManager
    @EnvironmentObject var navigationManager: NavigationManager

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Select variables
    @State private var isSelectionMode = false
    @State private var selectedMediaIds: Set<UUID> = []

    // Settings
    @State private var showSettings = false

    // Scroll variables
    @State private var isScrolled = false

    // Delete variables
    @State private var mediaToDelete: Storage?
    @State private var isDeletingMedia: Bool = false
    @State private var isDeletingSelectedMedia: Bool = false
    @State private var swipedPhotoId: UUID? = nil

    // Toast
    @State private var showLimitToast: Bool = false
    
    //Widget
    @State private var widgetSelectedStorage: Storage?
    @State private var showWidgetDetail: Bool = false
    
    @Query(sort: \Storage.createdAt, order: .reverse)
    private var allPhotos: [Storage]
    
    private var photos: [Storage] {
        allPhotos.filter { $0.expiredAt > Date() }
    }
    
    private var shouldShowScrolledState: Bool {
        photos.count > 0 && isScrolled
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if photos.isEmpty {
                        GalleryEmptyState()
                    } else {
                        GalleryList(
                            photos: photos,
                            mediaLimit: MEDIA_LIMIT,
                            isSelectionMode: $isSelectionMode,
                            selectedMediaIds: $selectedMediaIds,
                            swipedPhotoId: $swipedPhotoId,
                            isScrolled: $isScrolled,
                            mediaToDelete: $mediaToDelete,
                            isDeletingMedia: $isDeletingMedia,
                            onDeleteConfirmed: { media in
                                withAnimation {
                                    deleteMedia(media)
                                }
                            }
                        )
                    }
                }

                // Same fade technique as the top scroll overlay below, just flipped
                // vertically: opaque lightBase nearest the edge, fading to clear
                // going inward. Its own full-bounds ZStack layer (rather than a
                // `.background` on the button row) so it sits above the list and
                // reaches the true screen edge via `ignoresSafeArea`, independent of
                // the button row's own safe-area-inset layout. Taller behind the
                // selection action bar, shorter behind the lone capture button.
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.lightBase, location: 0.0),
                        Gradient.Stop(color: Color.lightBase.opacity(0.8), location: 0.4),
                        Gradient.Stop(color: .clear, location: 1.0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: isSelectionMode ? 140 : 100)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.2), value: isSelectionMode)

                VStack {
                    Spacer()
                    bottomBar
                }
            }
            .onAppear {
                if navigationManager.shouldShowDetail, let mediaId = navigationManager.selectedMediaId {
                    print("onAppear: Navigating with pending detail navigation: \(mediaId)")
                    
                    if showWidgetDetail {
                        showWidgetDetail = false
                        widgetSelectedStorage = nil
                    }
                    
                    if let storage = photos.first(where: { $0.id == mediaId }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            selectedMediaIds.removeAll()
                            isSelectionMode = false
                            showDetailForStorage(storage)
                        }
                    } else {
                        print("onAppear: Media not found in photos array: \(mediaId)")
                        navigationManager.resetDetailNavigation()
                    }
                }
            }
            .onChange(of: navigationManager.shouldShowDetail) { oldValue, newValue in
                print("onChange(navigationManager.shouldShowDetail): shouldShowDetail changed: \(oldValue) -> \(newValue)")
                if newValue, let mediaId = navigationManager.selectedMediaId {
                    if let storage = photos.first(where: { $0.id == mediaId }) {
                        if showWidgetDetail {
                            showWidgetDetail = false
                            widgetSelectedStorage = nil
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedMediaIds.removeAll()
                            isSelectionMode = false
                            showDetailForStorage(storage)
                        }
                    } else {
                        navigationManager.resetDetailNavigation()
                    }
                }
            }
            .toast(
                isShowing: $showLimitToast,
                message: "Delete or wait for one to clear automatically to add new snap.",
                icon: "exclamationmark.triangle",
                duration: 3.0
            )
            .background(Color.lightBase)
            .navigationBarTitleDisplayMode(shouldShowScrolledState ? .inline : .large)
            .toolbar {
                // iOS 26 wraps ToolbarItem content in an auto-sized Liquid Glass
                // background by default, which clips this taller title+count block
                // down to a small pill. `.sharedBackgroundVisibility(.hidden)` opts
                // it out of that grouping so it renders at full size, as documented at
                // https://iifx.dev/en/articles/457777731/bypassing-the-liquid-glass-left-aligned-toolbar-text-in-swiftui-ios-26
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        titleToolbarContent
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        titleToolbarContent
                    }
                }

                // One item holding both buttons, with `.sharedBackgroundVisibility(.hidden)`
                // so iOS 26 doesn't glass the whole group — only each button's own
                // explicit .glassEffect renders, keeping them visually separate.
                // Explicit trailing padding gives exact control over the edge margin
                // instead of relying on the system's default toolbar inset.
                // Settings is always reachable; Select only makes sense once there's
                // something to select, so it's the only one gated on `!photos.isEmpty`.
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: isSelectionMode ? 0 : -16) {
                            Button {
                                showSettings = true
                            } label: {
                                CircleButton(icon: "gear")
                            }
                            if !photos.isEmpty {
                                SelectButton(
                                    isSelectionMode: $isSelectionMode,
                                    selectedMediaIds: $selectedMediaIds,
                                    swipedPhotoId: $swipedPhotoId
                                )
                            }
                        }
                        .padding(.top, shouldShowScrolledState ? 0 : 8)
                        .padding(.trailing, (photos.isEmpty || isSelectionMode) ? -8 : -20)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .animation(.easeInOut(duration: 0.2), value: shouldShowScrolledState)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 4) {
                            Button {
                                showSettings = true
                            } label: {
                                CircleButton(icon: "gear")
                            }
                            if !photos.isEmpty {
                                SelectButton(
                                    isSelectionMode: $isSelectionMode,
                                    selectedMediaIds: $selectedMediaIds,
                                    swipedPhotoId: $swipedPhotoId
                                )
                            }
                        }
                        .padding(.top, shouldShowScrolledState ? 0 : 8)
                        .padding(.trailing, (photos.isEmpty || isSelectionMode) ? 8 : 0)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .contentShape(Rectangle())
                        .animation(.easeInOut(duration: 0.2), value: shouldShowScrolledState)
                    }
                }
            }
            .overlay(alignment: .top) {
                if shouldShowScrolledState {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color.lightBase, location: 0.0),
                            Gradient.Stop(color: Color.lightBase.opacity(0.8), location: 0.6),
                            Gradient.Stop(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            }
            
            
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                    if navigationManager.shouldShowDetail, let mediaId = navigationManager.selectedMediaId {
                        print("onChange(scenePhase): Navigating with pending detail navigation: \(mediaId)")
                        
                        if let storage = photos.first(where: { $0.id == mediaId }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                selectedMediaIds.removeAll()
                                isSelectionMode = false
                                showDetailForStorage(storage)
                            }
                        } else {
                            print("onChange(scenePhase): Media not found in photos array: \(mediaId)")
                            navigationManager.resetDetailNavigation()
                        }
                    }
                }
            
            if newPhase == .background {
                Task { @MainActor in
                    await
                    DeletionService.shared.performCleanup(modelContext: modelContext)
                }
            }
        }
        .onChange(of: timer.currentTime) {
            Task { @MainActor in
                await DeletionService.shared.performCleanup(modelContext: modelContext)
            }
        }
        .fullScreenCover(isPresented: $showWidgetDetail) {
            navigationManager.resetDetailNavigation()
            widgetSelectedStorage = nil
        } content: {
            if let storage = widgetSelectedStorage {
                DetailView(selectedStorage: .constant(storage), showCover: $showWidgetDetail)
            }
        }

    }

    @ViewBuilder
    private var bottomBar: some View {
        // Both bars stay mounted permanently and cross-fade via opacity/scale
        // instead of an `if isSelectionMode` swap. A freshly-inserted
        // .glassEffect() view flashes on the frame it's first inserted while
        // its backdrop sampling initializes (same issue fixed for the
        // per-photo swipe-delete button in GalleryList) — staying mounted
        // avoids re-triggering that flash on every selection-mode toggle.
        ZStack {
            CaptureButton(photoCount: photos.count, mediaLimit: MEDIA_LIMIT) {
                if photos.count < MEDIA_LIMIT {
                    navigationManager.navigate(to: .camera)
                } else {
                    if showLimitToast {
                        showLimitToast = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showLimitToast = true
                            }
                        }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showLimitToast = true
                        }
                    }
                }
            }
            .opacity(isSelectionMode ? 0 : 1)
            .scaleEffect(isSelectionMode ? 0.92 : 1)
            .allowsHitTesting(!isSelectionMode)

            SelectionActionBar(
                photos: photos,
                selectedMediaIds: selectedMediaIds,
                isConfirmingDelete: $isDeletingSelectedMedia,
                onDeleteTapped: {
                    if !selectedMediaIds.isEmpty {
                        isDeletingSelectedMedia = true
                    }
                },
                onDeleteConfirmed: bulkDeleteMedia
            )
            .opacity(isSelectionMode ? 1 : 0)
            .scaleEffect(isSelectionMode ? 1 : 0.92)
            .allowsHitTesting(isSelectionMode)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelectionMode)
    }

    @ViewBuilder
    private var titleToolbarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !shouldShowScrolledState {
                Text("Today")
                    .font(.spaceGroteskBold(size: 34))
                    .foregroundStyle(Color.darkerBlueBase)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            GalleryCount(currentCount: photos.count)
        }
        .padding(.top, shouldShowScrolledState ? 0 : 70)
        .animation(.easeInOut(duration: 0.2), value: shouldShowScrolledState)
        .fixedSize()
    }

    private func deleteMedia(_ media: Storage) {
        modelContext.delete(media)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete photo: \(error.localizedDescription)")
        }
    }
    
    private func bulkDeleteMedia() {
        let mediaToDelete = photos.filter { selectedMediaIds.contains($0.id) }
        
        for media in mediaToDelete {
            modelContext.delete(media)
        }
        
        do {
            try modelContext.save()
            withAnimation {
                selectedMediaIds.removeAll()
                isSelectionMode = false
            }
        } catch {
            print("Failed to delete selected photos: \(error.localizedDescription)")
        }
    }
    
    private func showDetailForStorage(_ storage: Storage) {
        widgetSelectedStorage = storage
        showWidgetDetail = true
    }
}

#Preview {
    GalleryView()
        .environmentObject(TimerManager.shared)
        .environmentObject(NavigationManager.shared)
}
