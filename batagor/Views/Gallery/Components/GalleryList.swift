//
//  GalleryList.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct GalleryList: View {
    let photos: [Storage]
    let mediaLimit: Int

    @Binding var isSelectionMode: Bool
    @Binding var selectedMediaIds: Set<UUID>
    @Binding var swipedPhotoId: UUID?
    @Binding var isScrolled: Bool
    @Binding var mediaToDelete: Storage?
    @Binding var isDeletingMedia: Bool

    private let topScrollThreshold: CGFloat = 155
    private let bottomScrollThreshold: CGFloat = 145

    @State private var lastScrollPosition: CGFloat = 0
    @State private var swipeOffsets: [UUID: CGFloat] = [:]
    @State private var shouldAnimateSwipe: Set<UUID> = []
    @State private var isDragging: Set<UUID> = []
    @State private var hapticTrigger = false
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var gestureDirection: [UUID: String] = [:]

    var body: some View {
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
                                let threshold: CGFloat = isScrolled ? topScrollThreshold : bottomScrollThreshold
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

                if photos.count >= mediaLimit {
                    GalleryLimitBanner()
                        .padding(.horizontal)
                        .padding(.bottom, 17)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.lightBase)
                }

                ForEach(photos) { photo in
                    // Kept permanently mounted (visibility driven only by scale/opacity/
                    // hit-testing) instead of behind `if swipedPhotoId == photo.id`. A
                    // lone .glassEffect view flashes on the frame it's first inserted
                    // into the hierarchy while its backdrop sampling initializes —
                    // structurally mounting it fresh on every swipe reveal was exactly
                    // that moment. Staying mounted means that init cost happens once,
                    // off-screen, and reveals are pure animated scale/opacity.
                    let deleteButton = Button {
                        mediaToDelete = photo
                        isDeletingMedia = true
                        withAnimation {
                            swipeOffsets[photo.id] = 0
                            swipedPhotoId = nil
                        }
                    } label: {
                        CircularSwipeButton(icon: "trash")
                    }

                    ZStack(alignment: .trailing) {
                        HStack {
                            Spacer()
                            Group {
                                if #available(iOS 26.0, *) {
                                    GlassEffectContainer {
                                        deleteButton
                                    }
                                } else {
                                    deleteButton
                                }
                            }
                            .padding(.trailing, 20)
                            .scaleEffect(swipedPhotoId == photo.id ? 1.0 : 0.0)
                            .opacity(swipedPhotoId == photo.id ? 1.0 : 0.0)
                            .allowsHitTesting(swipedPhotoId == photo.id)
                        }
                        .animation(.interpolatingSpring(stiffness: 300, damping: 15).delay(0.1), value: swipedPhotoId)

                        GalleryItem(
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
                    .padding(.vertical, 8)
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
        .onAppear {
            hapticGenerator.prepare()
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
}
