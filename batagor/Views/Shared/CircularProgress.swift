//
//  CircularProgress.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 05/11/25.
//

import SwiftUI

struct CircularProgress: View {
    let current: Int
    let total: Int
    var lineWidth: CGFloat = 3
    var size: CGFloat = 20
    var isShowText: Bool = false
    var isShowCount: Bool = false
    var foregroundColor: Color = Color.darkBase
    var font: Font = .spaceGroteskMedium(size: 17)
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
        .frame(width: size, height: size)
        
        if isShowText {
            Text("\(current) / \(total) Snaps")
                .font(font)
                .foregroundStyle(foregroundColor)
        } else if isShowCount {
            Text("\(current) / \(total)")
                .font(font)
                .foregroundStyle(foregroundColor)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        CircularProgress(current: 5, total: 24, isShowText: true)
        CircularProgress(current: 12, total: 24)
        CircularProgress(current: 24, total: 24)
    }
}
