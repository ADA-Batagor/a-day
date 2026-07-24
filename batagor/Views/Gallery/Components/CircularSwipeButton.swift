//
//  CircularSwipeButton.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 07/11/25.
//

import SwiftUI

struct CircularSwipeButton: View {
    let icon: String
    let backgroundColor: Color
    let iconColor: Color
    let size: CGFloat
    
    init(
        icon: String,
        backgroundColor: Color = .batagorDestroy,
        iconColor: Color = .white,
        size: CGFloat = 56
    ) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(backgroundColor)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(iconColor)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CircularSwipeButton(icon: "trash", backgroundColor: Color.red, iconColor: Color.white, size: 60)
}
