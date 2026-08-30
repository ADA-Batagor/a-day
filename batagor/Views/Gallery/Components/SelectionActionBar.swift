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

    @Binding var isConfirmingDelete: Bool

    let onDeleteTapped: () -> Void
    let onDeleteConfirmed: () -> Void

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

            // Dialog hangs off the delete button itself, not the GalleryView root,
            // so iOS 26 morphs it out of the button the user actually tapped.
            BulkDeleteButton(isDisabled: selectedMediaIds.isEmpty, action: onDeleteTapped)
                .confirmationDialog(
                    "Don't need this \(selectedMediaIds.count) snaps anymore?",
                    isPresented: $isConfirmingDelete,
                    titleVisibility: .visible
                ) {
                    Button("Delete \(selectedMediaIds.count) Snaps", role: .destructive) {
                        onDeleteConfirmed()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will delete it for good. This action can't be undone.")
                }
        }
        .padding(.horizontal)
    }
}

#Preview {
    SelectionActionBar(
        photos: [],
        selectedMediaIds: [],
        isConfirmingDelete: .constant(false),
        onDeleteTapped: {},
        onDeleteConfirmed: {}
    )
}
