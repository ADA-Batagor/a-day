//
//  GalleryItemView.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 21/10/25.
//

import SwiftUI
import CoreLocation

struct GalleryItemView: View {
    let storage: Storage
    
    @Binding var isSelecting: Bool
    @Binding var isSelected: Bool
    @Binding var isSwiped: Bool
    
    @State private var selectedStorage: Storage?
    @State private var showCover: Bool = false
    @State private var videoDuration: Double?
    
    @StateObject private var geocodeManager = ReverseGeocodeManager()
    
    var body: some View {
        ZStack (alignment: .bottomLeading) {
            if let image = StorageManager.shared.loadUIImage(fileURL: storage.thumbnailPath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .onTapGesture {
                        if isSelecting {
                            isSelected.toggle()
                        } else if !isSwiped {
                            selectedStorage = storage
                            showCover = true
                        }
                    }
            }
        }
        .overlay(alignment: .topTrailing) {
            if storage.isVideo, let duration = videoDuration {
                ZStack(alignment: .topTrailing) {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .black.opacity(0.7), location: 0.0),
                            Gradient.Stop(color: .black.opacity(0.4), location: 0.15),
                            Gradient.Stop(color: .black.opacity(0.15), location: 0.2),
                            Gradient.Stop(color: .clear, location: 0.3)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                    
                    Text(TimeFormatter.formatVideoDuration(duration))
                        .font(.spaceGroteskRegular(size: 13))
                        .foregroundColor(.lightBase)
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 0,
                            bottomLeading: 0,
                            bottomTrailing: 12,
                            topTrailing: 12
                        )
                    )
                )
                .allowsHitTesting(false)
            }
                
        }
        .overlay(alignment: .bottom) {
            if !isSelecting {
                TimeRemainingBar(storage: storage)
            }
            
             if isSelecting && isSelected {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.blueBase, lineWidth: 3)
                    
                    Circle()
                        .fill(Color.blueBase)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.darkBase)
                        )
                        .padding(8)
                }
            }
            
        }
        .fullScreenCover(isPresented: $showCover) {
            DetailView(selectedStorage: $selectedStorage, showCover: $showCover)
        }
        .task {
            if storage.isVideo {
                videoDuration = await TimeFormatter.getVideoDuration(from: storage.mainPath)
            }
        }
    }
}

#Preview {
    GalleryItemView(storage: Storage(
        createdAt: Date(),
        expiredAt: 20000,
        mainPath: URL(string: "https://images.unsplash.com/photo-1761405378282-e819a65cb493?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1364")!,
        thumbnailPath: URL(string: "https://images.unsplash.com/photo-1761405378282-e819a65cb493?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1364")!
        
    ), isSelecting: .constant(false), isSelected: .constant(true), isSwiped: .constant(false))
    .environmentObject(SharedTimerManager.shared)
}
