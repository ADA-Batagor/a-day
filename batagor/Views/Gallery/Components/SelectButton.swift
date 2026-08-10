//
//  SelectButton.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct SelectButton: View {
    @Binding var isSelectionMode: Bool
    @Binding var selectedMediaIds: Set<UUID>
    @Binding var swipedPhotoId: UUID?

    var body: some View {
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
            Group {
                if #available(iOS 26.0, *) {
                    Text(isSelectionMode ? "Cancel" : "Select")
                        .bold()
                        .padding(.horizontal, 15)
                        .frame(height: 44)
                        .foregroundStyle(isSelectionMode ? Color.lightBase : Color.darkBase)
                        .glassEffect(
                            isSelectionMode ? .regular.tint(Color.yellow60).interactive() : .regular.interactive(),
                            in: .capsule
                        )
                } else {
                    Text(isSelectionMode ? "Cancel" : "Select")
                        .bold()
                        .padding(.horizontal, 15)
                        .frame(height: 44)
                        .foregroundStyle(isSelectionMode ? Color.lightBase : Color.darkBase)
                        .background(isSelectionMode ? Color.yellow60 : Color.yellow30)
                        .cornerRadius(40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.yellow60, lineWidth: 1)
                        )
                }
            }
        }
    }
}

#Preview {
    SelectButton(
        isSelectionMode: .constant(false),
        selectedMediaIds: .constant([]),
        swipedPhotoId: .constant(nil)
    )
}
