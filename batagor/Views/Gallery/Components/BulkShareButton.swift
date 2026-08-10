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
            Group {
                if #available(iOS 26.0, *) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.spaceGroteskBold(size: 17))
                        .foregroundStyle(Color.darkBase)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.tint(Color.blueBase).interactive(), in: RoundedRectangle(cornerRadius: 20))
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.spaceGroteskBold(size: 17))
                        .foregroundStyle(Color.darkBase)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.blueBase)
                        .cornerRadius(20)
                }
            }
        }
        .disabled(selectedMediaIds.isEmpty)
    }
}

#Preview {
    BulkShareButton(photos: [], selectedMediaIds: [])
}
