//
//  SettingsRow.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 18/11/25.
//

import SwiftUI

struct SettingsRow: View {
    let title: String
    var statusText: String? = nil
    var showDrillIn: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.spaceGroteskMedium(size: 17))
                    .foregroundStyle(Color.darkBase)

                Spacer()

                if let statusText {
                    Text(statusText)
                        .font(.spaceGroteskRegular(size: 15))
                        .foregroundStyle(Color.dark20)
                }

                if showDrillIn {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dark20)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.light20)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 8) {
        SettingsRow(title: "Camera", statusText: "Allowed") {}
        SettingsRow(title: "Contact us") {}
    }
    .padding()
    .background(Color.lightBase)
}
