//
//  CustomAlert.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 13/11/25.
//

import SwiftUI

struct CustomAlert: View {
    var title: String
    var message: String
    var buttonTitle: String = "Ok"
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.spaceGroteskSemiBold(size: 17))
                    .foregroundStyle(Color.black)
                
                Text(message)
                    .font(.spaceGroteskRegular(size: 13))
                    .foregroundStyle(Color.darkBase)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Button {
                onSubmit()
            } label: {
                Text(buttonTitle)
                    .font(.spaceGroteskSemiBold(size: 17))
                    .foregroundStyle(Color.blue70Hue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .frame(width: 270)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.lightBase)
                .shadow(color: .black.opacity(0.3), radius: 40, y: 20)
        )
        .transition(.scale(scale: 1.1).combined(with: .opacity))
    }
}

#Preview {
    CustomAlert(
        title: "Alert",
        message: "Alert message",
        buttonTitle: "Yes",
        onSubmit: ({print("halo")})
    )
}
