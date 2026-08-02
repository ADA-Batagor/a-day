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
            Image(systemName: "trash")
                .font(.spaceGroteskBold(size: 17))
                .foregroundStyle(Color.darkBase)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.blueBase)
        .cornerRadius(20)
        .disabled(isDisabled)
    }
}

#Preview {
    BulkDeleteButton(isDisabled: false) {}
}
