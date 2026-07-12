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
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.rgb(red: 250, green: 244, blue: 230), location: 0.0),
                        Gradient.Stop(color: Color.rgb(red: 237, green: 243, blue: 254), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Button {
                            showCover = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.spaceGroteskSemiBold(size: 22))
                                .foregroundStyle(Color.darkBase)
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .center, spacing: 25) {
                            if previousPage == .camera {
                                Button {
                                    showCover = false
                                    NavigationManager.shared.navigate(to: .gallery)
                                } label: {
                                    Text("All Media")
                                        .font(.spaceGroteskSemiBold(size: 18))
                                        .foregroundStyle(Color.darkBase)
                                }
                            }
                            
                            if let selectedStorage = selectedStorage {
                                ShareLink(item: selectedStorage.mainPath) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.spaceGroteskSemiBold(size: 22))
                                        .foregroundStyle(Color.darkBase)
                                }
                                
                                Button {
                                    showDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.spaceGroteskSemiBold(size: 22))
                                        .foregroundStyle(Color.darkBase)
                                }
                                .customConfirmationDialog(
                                    "Don't need this snap anymore?",
                                    isPresented: $showDeleteConfirmation,
                                    actionTitle: "Delete",
                                    actionColor: .redBase,
                                    action: {
                                        DeletionService.shared.manualDelete(modelContext: modelContext, storage: selectedStorage)
                                    },
                                    cancel: {},
                                    message:"This will delete it for good. This action can't be undone."
                                )
                            }
                        }
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(storages, id: \.self) { storage in
                                    VStack {
                                        if storage.mainPath.pathExtension == "mp4" {
                                            if selectedThumbnail == storage {
                                                VideoPlayer(player: player)
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
                                            Spacer()
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text("Come")
                                                        .font(.spaceGroteskSemiBold(size: 15))
                                                        .foregroundStyle(Color.darkBase)
                                                    Text(storage.createdAt.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.spaceGroteskRegular(size: 15))
                                                        .foregroundStyle(Color.darkBase)
                                                }
                                                
                                                HStack {
                                                    Text("Gone")
                                                        .font(.spaceGroteskSemiBold(size: 15))
                                                        .foregroundStyle(Color.darkBase)
                                                    Text(storage.expiredAt.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.spaceGroteskRegular(size: 15))
                                                        .foregroundStyle(Color.darkBase)
                                                }
                                                
                                                if let location = storage.locationName,
                                                   let city = storage.locationCity {
                                                    Text("\(location), \(city)")
                                                        .font(.spaceGroteskRegular(size: 15))
                                                        .foregroundStyle(Color.darkBase)
                                                    
                                                    MapThumbnail(storage: storage)
                                                        .clipShape(.rect(cornerRadius: 12))
                                                        .containerRelativeFrame(.vertical) { height, _ in
                                                            height * 0.2
                                                        }
                                                }
                                            }
                                        }
                                        
                                    }
                                    .id(storage.id)
                                    .containerRelativeFrame(.horizontal)
                                    .simultaneousGesture(simultaneousGesture())
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
                            if let new: Storage = newValue {
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
                
                if !isShowedDetail {
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
            .ignoresSafeArea(.container)
        }
        .overlay(alignment: .bottom) {
            if let selectedStorage = selectedStorage {
                RemainingTime(storage: selectedStorage, variant: .large)
            }
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
                    //                    if !isShowedDetail {
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
                    //                    } else {
                    //                        if abs(value.translation.height) > abs(value.translation.width) {
                    //                            blockHorizontal = true
                    //                        }
                    //                    }
                }
                .onEnded { value in
                    lastOffset = offset
                    
                    //                    if !isShowedDetail {
                    if !isZoomed {
                        if value.translation.height > 150 {
                            withAnimation(.easeOut(duration: 0.3)) {
                                dismissOffset = CGSize(width: 0, height: value.translation.height > 0 ? 1000 : -1000)
                                dismissScale = 0
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showCover = false
                            }
//                        } else if value.translation.height < -50 {
//                            withAnimation(.bouncy) {
//                                isShowedDetail = true
//                            }
                        } else {
                            withAnimation(.spring()) {
                                dismissOffset = .zero
                                dismissScale = 1.0
                            }
                        }
                    }
                    //                    } else {
                    //                        if value.translation.height > value.translation.width &&
                    //                            value.translation.height > 50 {
                    //                            withAnimation(.bouncy) {
                    //                                isShowedDetail = false
                    //                            }
                    //                        }
                    //                    }
                    
                    blockHorizontal = false
                }
        )
    }
}

#Preview {
    DetailView(selectedStorage: .constant(
        Storage(
            mainPath: URL(string: "https://example.com")!,
            thumbnailPath: URL(string: "https://example.com")!
        )
    ), showCover: .constant(true))
}
