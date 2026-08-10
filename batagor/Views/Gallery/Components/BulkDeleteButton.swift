//
//  BulkDeleteButton.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct BulkDeleteButton: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Group {
                if #available(iOS 26.0, *) {
                    Image(systemName: "trash")
                        .font(.spaceGroteskBold(size: 17))
                        .foregroundStyle(Color.darkBase)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.tint(Color.blueBase).interactive(), in: RoundedRectangle(cornerRadius: 20))
                } else {
                    Image(systemName: "trash")
                        .font(.spaceGroteskBold(size: 17))
                        .foregroundStyle(Color.darkBase)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.blueBase)
                        .cornerRadius(20)
                }
            }
        }
        .disabled(isDisabled)
    }
}

#Preview {
    BulkDeleteButton(isDisabled: false) {}
}
