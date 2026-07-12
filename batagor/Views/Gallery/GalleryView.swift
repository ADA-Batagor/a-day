//
//  GalleryView.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 21/10/25.
//

import SwiftUI
import SwiftData

struct GalleryView: View {
    let TOP_SCROLL_THRESHOLD: CGFloat = 155
    let BOTTOM_SCROLL_THRESHOLD: CGFloat = 145
    let MEDIA_LIMIT = 24
    let TITLE_TOP_OFFSET: CGFloat = 70
    let SUBTITLE_TOP_OFFSET: CGFloat = 25
    
    @EnvironmentObject var timer: SharedTimerManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    // Select variables
    @State private var isSelectionMode = false
    @State private var isSelected = false
    @State private var selectedMediaIds: Set<UUID> = []
    @State private var lastScrollPosition: CGFloat = 0
    
    // Scroll variables
    @State private var isScrolled = false
    @State private var scrollOffset: CGFloat = 0
    
    // Delete variables
    @State private var mediaToDelete: Storage?
    @State private var isDeletingMedia: Bool = false
    @State private var isDeletingSelectedMedia: Bool = false
    @State private var swipedPhotoId: UUID? = nil
    @State private var swipeOffsets: [UUID: CGFloat] = [:]
    @State private var shouldAnimateSwipe: Set<UUID> = []
    @State private var isDragging: Set<UUID> = []
    @State private var hapticTrigger = false
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var gestureDirection: [UUID: String] = [:]
    
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
                        EmptyStateView
                    } else {
                        GalleryListView
                    }
                }
                
                VStack {
                    Spacer()
                    if isSelectionMode {
                        HStack {
                            BulkShare
                            
                            Spacer()
                            
                            HStack {
                                Text("\(selectedMediaIds.count) Snaps Selected")
                                    .font(.spaceGroteskSemiBold(size: 17))
                                    .foregroundStyle(Color.darkBase)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.accentBase)
                            .cornerRadius(20)
                            
                            Spacer()
                            
                            Button {
                                if !selectedMediaIds.isEmpty {
                                    isDeletingSelectedMedia = true
                                }
                            } label : {
                                Image(systemName: "trash")
                                    .font(.spaceGroteskBold(size: 17))
                                    .foregroundStyle(Color.darkBase)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.blueBase)
                            .cornerRadius(20)
                            .disabled(selectedMediaIds.isEmpty ? true : false)
                        }
                        .padding(.horizontal)
                    } else {
                        HStack {
                            Spacer()
                            Button {
                                if photos.count < 24 {
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
                            } label: {
                                HStack {
                                    Image(systemName: "camera")
                                        .font(.spaceGroteskSemiBold(size: 17))
                                        .foregroundStyle(photos.count < MEDIA_LIMIT ? Color.darkBase : Color.light50)
                                    Text("Capture Snaps")
                                        .font(.spaceGroteskSemiBold(size: 17))
                                        .foregroundStyle(photos.count < MEDIA_LIMIT ? Color.darkBase : Color.light50)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(photos.count < MEDIA_LIMIT ? Color.blueBase : Color.dark20)
                                .cornerRadius(20)
                            }
                            Spacer()
                        }
                    }
                    
                }
                .background(alignment: .bottom) {
                    VStack {
                        Spacer()
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: Color.lightBase, location: 0.0),
                                Gradient.Stop(color: .clear, location: 0.5)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 96)
                    }
                    .ignoresSafeArea()
                }
            }
            .onAppear {
                hapticGenerator.prepare()

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
                ToolbarItem(placement: .topBarLeading) {
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
                }
                
                if !photos.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        VStack {
                            SelectButton
                        }
                        .padding(.top, shouldShowScrolledState ? 0 : 25)
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
        .customConfirmationDialog(
            "Don't need this snap anymore?",
            isPresented: $isDeletingMedia,
            actionTitle: "Delete",
            actionColor: .redBase,
            action: {
                if let media = mediaToDelete {
                    withAnimation {
                        deleteMedia(media)
                    }
                    mediaToDelete = nil
                }
            },
            cancel: {
                mediaToDelete = nil
            },
            message:"This will delete it for good. This action can't be undone."
        )
        .customConfirmationDialog(
            "Don't need this \(selectedMediaIds.count) snaps anymore?",
            isPresented: $isDeletingSelectedMedia,
            actionTitle: "Delete \(selectedMediaIds.count) Snaps",
            actionColor: .redBase,
            action: {
                bulkDeleteMedia()
            },
            message: "This will delete it for good. This action can't be undone."
        )
        .fullScreenCover(isPresented: $showWidgetDetail) {
            navigationManager.resetDetailNavigation()
            widgetSelectedStorage = nil
        } content: {
            if let storage = widgetSelectedStorage {
                DetailView(selectedStorage: .constant(storage), showCover: $showWidgetDetail)
            }
        }
        
    }
    
    private var GalleryListView: some View {
        List {
            Section {
                HStack {
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
                                let scrollDelta = newValue - oldValue
                                let threshold: CGFloat = isScrolled ? TOP_SCROLL_THRESHOLD : BOTTOM_SCROLL_THRESHOLD
                                let isScrollable = newValue < threshold
                                
                                Task { @MainActor in
                                    if isScrolled != isScrollable {
                                        isScrolled = isScrollable
                                    }
                                    lastScrollPosition = scrollDelta
                                }
                            }
                    }
                )
                
                if photos.count >= MEDIA_LIMIT {
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "sun.max")
                                .resizable()
                                .fontWeight(.semibold)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your day is full!")
                                    .font(.spaceGroteskBold(size: 17))
                                    .foregroundStyle(Color.darkBase)
                                Text("To add new snap, wait for one disappear or delete an existing one to make room.")
                                    .font(.spaceGroteskRegular(size: 17))
                                    .foregroundStyle(Color.darkBase)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    .background(Color.yellow50)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.bottom, 17)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.lightBase)
                }
                
                ForEach(photos) { photo in
                    ZStack(alignment: .trailing) {
                        if swipedPhotoId == photo.id {
                            HStack {
                                Spacer()
                                Button {
                                    mediaToDelete = photo
                                    isDeletingMedia = true
                                    withAnimation {
                                        swipeOffsets[photo.id] = 0
                                        swipedPhotoId = nil
                                    }
                                } label: {
                                    CircularSwipeButton(icon: "trash")
                                }
                                .padding(.trailing, 20)
                                .scaleEffect(swipedPhotoId == photo.id ? 1.0 : 0.0)
                                .opacity(swipedPhotoId == photo.id ? 1.0 : 0.0)
                            }
                            .animation(.interpolatingSpring(stiffness: 300, damping: 15).delay(0.1), value: swipedPhotoId)
                        }
                        
                        GalleryItemView(
                            storage: photo,
                            isSelecting: $isSelectionMode,
                            isSelected: selectionBinding(for: photo.id),
                            isSwiped: swipedBinding(for: photo.id)
                        )
                        .offset(x: swipeOffsets[photo.id] ?? 0)
                        .animation(shouldAnimateSwipe.contains(photo.id) ? .spring(response: 0.3, dampingFraction: 0.75) : .none, value: swipeOffsets[photo.id])
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                .onChanged { gesture in
                                    if isSelectionMode { return }
                                    
                                    isDragging.insert(photo.id)
                                    shouldAnimateSwipe.remove(photo.id)
                                    
                                    let horizontalMovement = gesture.translation.width
                                    let verticalMovement = gesture.translation.height
                                    
                                    if gestureDirection[photo.id] == nil {
                                        let absHorizontal = abs(horizontalMovement)
                                        let absVertical = abs(verticalMovement)
                                        
                                        if absHorizontal > 10 || absVertical > 10 {
                                            if absHorizontal > absVertical * 2.0 {
                                                gestureDirection[photo.id] = "horizontal"
                                            } else {
                                                gestureDirection[photo.id] = "vertical"
                                            }
                                        }
                                    }
                                    
                                    guard gestureDirection[photo.id] == "horizontal" else { return }
                                    
                                    if swipedPhotoId == photo.id && horizontalMovement < 0 {
                                        return
                                    }
                                    
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    
                                    if abs(horizontalMovement) > abs(verticalMovement) * 1.5 && horizontalMovement < 0 {
                                        swipeOffsets[photo.id] = max(horizontalMovement, -90)
                                        
                                        if horizontalMovement < -50 && !hapticTrigger {
                                            hapticGenerator.impactOccurred()
                                            hapticTrigger = true
                                        } else if horizontalMovement > -50 && hapticTrigger {
                                            hapticTrigger = false
                                        }
                                    } else if abs(horizontalMovement) > abs(verticalMovement) * 1.5 && horizontalMovement > 0 {
                                        if swipedPhotoId == photo.id {
                                            let resistance = horizontalMovement * 0.3
                                            swipeOffsets[photo.id] = min(-90 + resistance, 0)
                                        }
                                    }
                                    
                                }
                                .onEnded { gesture in
                                    if let previousId = swipedPhotoId, previousId != photo.id {
                                        shouldAnimateSwipe.insert(previousId)
                                        swipeOffsets[previousId] = 0
                                    }
                                    
                                    if isSelectionMode { return }
                                    
                                    isDragging.remove(photo.id)
                                    hapticTrigger = false
                                    
                                    let horizontalMovement = gesture.translation.width
                                    
                                    if gestureDirection[photo.id] == "horizontal" {
                                        let threshold: CGFloat = -50
                                        
                                        if horizontalMovement < threshold {
                                            if let previousId = swipedPhotoId, previousId != photo.id {
                                                swipeOffsets[previousId] = 0
                                            }
                                            
                                            shouldAnimateSwipe.insert(photo.id)
                                            swipeOffsets[photo.id] = -90
                                            swipedPhotoId = photo.id

                                        } else {
                                            shouldAnimateSwipe.insert(photo.id)
                                            swipeOffsets[photo.id] = 0
                                            if swipedPhotoId == photo.id {
                                                swipedPhotoId = nil
                                            }
                                        }
                                    } else {
                                        shouldAnimateSwipe.insert(photo.id)
                                        swipeOffsets[photo.id] = 0
                                    }
                                    
                                    gestureDirection.removeValue(forKey: photo.id)

                                }
                        )
                        .contentShape(Rectangle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 17)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.lightBase)
                }
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .onChange(of: swipedPhotoId) { oldValue, newValue in
            if let oldId = oldValue, newValue != oldId {
                swipeOffsets[oldId] = 0
            }
        }
        
    }
    
    private var EmptyStateView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Image(systemName: "cloud.sun")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.darkBase)
                
                VStack(alignment: .center, spacing: 4) {
                    Text("A clear day.")
                        .font(.spaceGroteskBold(size: 24))
                        .foregroundStyle(Color.darkBase)
                    
                    Text("Let’s get your first snap. It’ll be here for 24 hours.")
                        .font(.spaceGroteskRegular(size: 17))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.darkBase)
                }
                .padding()
            }
            .padding()
        }
        .padding(.horizontal)
        
    }
    
    private var SelectButton: some View {
        Button {
            if isSelectionMode {
                selectedMediaIds.removeAll()
                swipedPhotoId = nil
                isSelectionMode = false
            } else {
                swipedPhotoId = nil
                isSelectionMode = true
            }
        } label: {
            Text(isSelectionMode ? "Cancel": "Select")
                .padding(.horizontal, 15)
                .padding(.vertical, 7)
                .foregroundStyle(isSelectionMode ? Color.lightBase : Color.darkBase)
                .background(isSelectionMode ? Color.yellow60 : Color.yellow30)
                .cornerRadius(40)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.yellow60, lineWidth: 1)
                )
        }
    }
    
    private var BulkShare: some View {
        let mediaToShare = photos
            .filter { selectedMediaIds.contains($0.id) }
            .map { $0.mainPath }
        
        return ShareLink(items: mediaToShare) {
            Image(systemName: "square.and.arrow.up")
                .font(.spaceGroteskBold(size: 17))
                .foregroundStyle(Color.darkBase)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.blueBase)
                .cornerRadius(20)
        }
        .disabled(selectedMediaIds.isEmpty ? true : false)
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
    
    private func selectionBinding(for mediaId: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedMediaIds.contains(mediaId) },
            set: { newValue in
                if newValue {
                    selectedMediaIds.insert(mediaId)
                } else {
                    selectedMediaIds.remove(mediaId)
                }
            }
        )
    }
    
    private func swipedBinding(for mediaId: UUID) -> Binding<Bool> {
        Binding(
            get: { swipedPhotoId == mediaId },
            set: { newValue in
                if newValue {
                    swipedPhotoId = mediaId
                } else {
                    swipedPhotoId = nil
                }
            }
        )
    }
    
    private func showDetailForStorage(_ storage: Storage) {
        widgetSelectedStorage = storage
        showWidgetDetail = true
    }
}

#Preview {
    GalleryView()
        .environmentObject(SharedTimerManager.shared)
        .environmentObject(NavigationManager.shared)
}
