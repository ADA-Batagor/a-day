//
//  GalleryLimitBanner.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct GalleryLimitBanner: View {
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "sun.max")
                    .resizable()
                    .fontWeight(.semibold)
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your day is full!")
                        .font(.spaceGroteskBold(size: 17))
                        .foregroundStyle(Color.darkBase)
                    Text("To add new snap, wait for one disappear or delete an existing one to make room.")
                        .font(.spaceGroteskRegular(size: 17))
                        .foregroundStyle(Color.darkBase)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(Color.yellow50)
        .cornerRadius(20)
    }
}

#Preview {
    GalleryLimitBanner()
        .padding()
}
