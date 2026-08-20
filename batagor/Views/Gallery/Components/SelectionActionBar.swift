//
//  SelectionActionBar.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct SelectionActionBar: View {
    let photos: [Storage]
    let selectedMediaIds: Set<UUID>
    let onDeleteTapped: () -> Void

    var body: some View {
        HStack {
            BulkShareButton(photos: photos, selectedMediaIds: selectedMediaIds)

            Spacer()

            // No background of its own — the shared blur band behind the whole
            // bottom bar (GalleryView) provides the backdrop now.
            Text("\(selectedMediaIds.count) Snaps Selected")
                .font(.spaceGroteskSemiBold(size: 17))
                .foregroundStyle(Color.darkBase)

            Spacer()

            BulkDeleteButton(isDisabled: selectedMediaIds.isEmpty, action: onDeleteTapped)
        }
        .padding(.horizontal)
    }
}

#Preview {
    SelectionActionBar(photos: [], selectedMediaIds: []) {}
}
