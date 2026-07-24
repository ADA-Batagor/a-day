//
//  FocusIndicator.swift
//  batagor
//
//  Created by Tude Maha on 12/07/2026.
//

import SwiftUI

struct FocusIndicator: View {
    @State private var scale: CGFloat = 1.2
    
    var body: some View {
        Rectangle()
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 70, height: 70)
            .scaleEffect(scale)
            .opacity(scale > 1.0 ? 0.0 : 1.0)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
    }
}

#Preview {
    FocusIndicator()
}
