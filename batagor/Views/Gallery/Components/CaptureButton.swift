//
//  CaptureButton.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct CaptureButton: View {
    let photoCount: Int
    let mediaLimit: Int
    let onCapture: () -> Void

    private var isAtLimit: Bool {
        photoCount >= mediaLimit
    }

    var body: some View {
        HStack {
            Spacer()
            Button(action: onCapture) {
                HStack {
                    Image(systemName: "camera")
                        .font(.spaceGroteskSemiBold(size: 17))
                        .foregroundStyle(isAtLimit ? Color.light50 : Color.darkBase)
                    Text("Capture Snaps")
                        .font(.spaceGroteskSemiBold(size: 17))
                        .foregroundStyle(isAtLimit ? Color.light50 : Color.darkBase)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(isAtLimit ? Color.dark20 : Color.blueBase)
                .cornerRadius(20)
            }
            Spacer()
        }
    }
}

#Preview {
    CaptureButton(photoCount: 5, mediaLimit: 24) {}
}
