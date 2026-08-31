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
                if isSelectionMode {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "xmark")
                            .bold()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(Color.darkBase)
                            .glassEffect(.regular.interactive(), in: .circle)
                    } else {
                        Image(systemName: "xmark")
                            .bold()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(Color.darkBase)
                            .contentShape(.circle)
                    }
                } else {
                    if #available(iOS 26.0, *) {
                        Text("Select")
                            .bold()
                            .padding(.horizontal, 15)
                            .frame(height: 44)
                            .foregroundStyle(Color.darkBase)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    } else {
                        Text("Select")
                            .bold()
                            .padding(.horizontal, 15)
                            .frame(height: 44)
                            .foregroundStyle(Color.darkBase)
                            .background(Color.yellow30)
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
}

#Preview {
    SelectButton(
        isSelectionMode: .constant(false),
        selectedMediaIds: .constant([]),
        swipedPhotoId: .constant(nil)
    )
}
