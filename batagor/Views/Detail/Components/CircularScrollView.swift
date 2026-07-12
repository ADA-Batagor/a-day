//
//  SwiftUIView.swift
//  batagor
//
//  Created by Tude Maha on 12/11/2025.
//

import SwiftUI

struct CircularScrollView: View {
    var storages: [Storage]
    @Binding var selectedStorage: Storage?
    @Binding var selectedThumbnail: Storage?
    @Binding var selectedVideo: Storage?
    var geo: GeometryProxy
    
    @State private var hasScrolledToInitial = false
    @State private var changeFromTap = false
    @State private var borderedThumbnail: Storage?
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(storages, id: \.self) { storage in
                            if let thumbnail = StorageManager.shared.loadUIImage(fileURL: storage.thumbnailPath) {
                                GeometryReader { insideGeo in
                                    let centerX = insideGeo.frame(in: .global).midX
                                    
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                        .preference(key: CenterThumbnailPreferenceKey.self, value: [storage.id: centerX])
                                }
                                .id(storage.id)
                                .frame(width: 40, height: 70)
                                .border(
                                    Color.blueBase,
                                    width: borderedThumbnail == storage ? 4 : 0
                                )
                                .clipShape(.rect(cornerRadius: 5))
                                .offset(y: -(1.8 / 2) * UIScreen.main.bounds.width)
                                .visualEffect { content, geometryProxy in
                                    content
                                        .rotationEffect(
                                            .init(degrees: thumbnailRotation(geometryProxy)),
                                            anchor: .center
                                        )
                                        .offset(x: -geometryProxy.frame(in: .scrollView(axis: .horizontal)).minX)
                                }
                                .onTapGesture {
                                    changeFromTap = true
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedStorage = storage
                                        selectedThumbnail = storage
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        changeFromTap = false
                                    }
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .safeAreaPadding(.horizontal, (geo.size.width * 0.5 - 20))
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .offset(y: geo.size.height * 0.83)
                .onAppear {
                    if let selectedStorage = selectedStorage, !hasScrolledToInitial {
                        borderedThumbnail = selectedStorage
                        withAnimation {
                            proxy.scrollTo(selectedStorage.id)
                        }
                        hasScrolledToInitial = true
                    }
                }
                .onChange(of: selectedThumbnail) { _, newValue in
                    borderedThumbnail = selectedStorage
                    if let new = newValue {
                        withAnimation {
                            proxy.scrollTo(new.id)
                        }
                    }
                }
                .onPreferenceChange(CenterThumbnailPreferenceKey.self) { centers in
                    if changeFromTap { return }
                    
                    if let best = centers.min(by: {
                        abs($0.value - (geo.size.width / 2)) < abs($1.value - (geo.size.width / 2))
                    }) {
                        if let choosen = storages.first(where: { $0.id == best.key }), hasScrolledToInitial {
                            selectedStorage = choosen
                            borderedThumbnail = choosen
                            
                            if choosen.mainPath.pathExtension == "mp4" {
                                selectedVideo = choosen
                            }
                        }
                    }
                }
            }
        }
    }
    
    nonisolated func thumbnailRotation(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        let width = proxy.size.width
        
        let progress = minX / width
        let angleForEachThumbnail: CGFloat = 6
        let cappedProgress = progress < 0 ? min(max(progress, -12), 0) : max(min(progress, 12), 0)
        
        return angleForEachThumbnail * cappedProgress
    }
    
    struct CenterThumbnailPreferenceKey: PreferenceKey {
        static var defaultValue: [UUID: CGFloat] = [:]
        
        static func reduce(value: inout [UUID : CGFloat], nextValue: () -> [UUID : CGFloat]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
}

//#Preview {
//    CircularScrollView()
//}
