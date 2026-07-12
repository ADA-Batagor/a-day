//
//  Knob.swift
//  batagor
//
//  Created by Tude Maha on 12/11/2025.
//

import SwiftUI

struct Knob: View {
    let tickCount = 27
    let startAngle = -90.0
    let endAngle = 90.0
    let tickLength: CGFloat = 25
    
    var body: some View {
        ZStack {
            ForEach(0..<tickCount, id: \.self) { i in
                let progress = Double(i) / Double(tickCount - 1)
                let angle = startAngle + progress * (endAngle - startAngle)
                
                Rectangle()
                    .fill(Color.darkBase)
                    .frame(width: 2, height: tickLength)
                    .offset(y: -(1.8 / 2) * UIScreen.main.bounds.width)
                    .rotationEffect(.degrees(angle))
            }
        }
    }
}

#Preview {
    Knob()
}
