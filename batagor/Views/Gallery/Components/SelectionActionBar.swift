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

            Group {
                if #available(iOS 26.0, *) {
                    Text("\(selectedMediaIds.count) Snaps Selected")
                        .font(.spaceGroteskSemiBold(size: 17))
                        .foregroundStyle(Color.darkBase)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.tint(Color.accentBase), in: RoundedRectangle(cornerRadius: 20))
                } else {
                    Text("\(selectedMediaIds.count) Snaps Selected")
                        .font(.spaceGroteskSemiBold(size: 17))
                        .foregroundStyle(Color.darkBase)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.accentBase)
                        .cornerRadius(20)
                }
            }

            Spacer()

            BulkDeleteButton(isDisabled: selectedMediaIds.isEmpty, action: onDeleteTapped)
        }
        .padding(.horizontal)
    }
}

#Preview {
    SelectionActionBar(photos: [], selectedMediaIds: []) {}
}
