//
//  GalleryEmptyState.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct GalleryEmptyState: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Image(systemName: "cloud.sun")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.darkBase)

                VStack(alignment: .center, spacing: 4) {
                    Text("A clear day.")
                        .font(.spaceGroteskBold(size: 24))
                        .foregroundStyle(Color.darkBase)

                    Text("Let’s get your first snap. It’ll be here for 24 hours.")
                        .font(.spaceGroteskRegular(size: 17))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.darkBase)
                }
                .padding()
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

#Preview {
    GalleryEmptyState()
}
