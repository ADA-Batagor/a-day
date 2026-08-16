//
//  FullScreenAlert.swift
//  batagor
//
//  Created by Tude Maha on 02/08/2026.
//

import SwiftUI

struct FullScreenAlert: View {
    var iconName: String
    var title: String
    var message: String
    var buttonText: String
    var buttonActionURL: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(alignment: .center, spacing: 15) {
                Image(systemName: iconName)
                    .font(.spaceGroteskBold(size: 60))
                Text(title)
                    .font(.spaceGroteskMedium(size: 20))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.spaceGroteskRegular(size: 15))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 20)
            
            if #available(iOS 26, *) {
                Button {
                    if let settingsURL = URL(
                        string: buttonActionURL
                    ) {
                        UIApplication.shared.open(settingsURL)
                    }
                } label: {
                    Text(buttonText)
                        .font(.spaceGroteskSemiBold(size: 15))
                        .foregroundStyle(Color.batagorLight)
                        .padding(15)
                        .glassEffect(.regular.interactive().tint(.adayPrimary))
                }
            } else {
                Button {
                    if let settingsURL = URL(
                        string: buttonActionURL
                    ) {
                        UIApplication.shared.open(settingsURL)
                    }
                } label: {
                    Text(buttonText)
                        .font(.spaceGroteskSemiBold(size: 15))
                        .foregroundStyle(Color.batagorLight)
                        .padding(15) 
                }
            }
        }
    }
}

#Preview {
    FullScreenAlert(
        iconName: "camera",
        title: "Allow A Day to access your camera and microphone",
        message: "This lets you share photos, record videos and preview effects.",
        buttonText: "Open Settings",
        buttonActionURL: UIApplication.openSettingsURLString
    )
}
