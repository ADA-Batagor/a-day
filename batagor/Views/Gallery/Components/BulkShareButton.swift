//
//  BulkShareButton.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct BulkShareButton: View {
    let photos: [Storage]
    let selectedMediaIds: Set<UUID>

    private var mediaToShare: [URL] {
        photos
            .filter { selectedMediaIds.contains($0.id) }
            .map { $0.mainPath }
    }

    var body: some View {
        ShareLink(items: mediaToShare) {
            Image(systemName: "square.and.arrow.up")
                .font(.spaceGroteskBold(size: 17))
                .foregroundStyle(Color.darkBase)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.blueBase)
                .cornerRadius(20)
        }
        .disabled(selectedMediaIds.isEmpty)
    }
}

#Preview {
    BulkShareButton(photos: [], selectedMediaIds: [])
}
