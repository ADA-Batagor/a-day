//
//  DetailBottomToolbar.swift
//  batagor
//
//  Created by Tude Maha on 11/11/2025.
//

import SwiftUI

struct DetailBottomToolbar: View {
    var selectedStorage: Storage
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            ShareLink(item: selectedStorage.mainPath) {
                CircleButton(icon: "square.and.arrow.up")
            }
            
            Spacer()
            
            Button {
                showDeleteConfirmation = true
            } label: {
                CircleButton(icon: "trash")
            }
            .confirmationDialog("Delete Photo", isPresented: $showDeleteConfirmation, titleVisibility: .hidden) {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        DeletionService.shared.manualDelete(modelContext: modelContext, storage: selectedStorage)
                    }
                }
            } message: {
                let ext = selectedStorage.isVideo ? "video" : "photo"
                Text("This \(ext) will delete it for good. This action can't be undone.")
                
            }
        }
    }
}
