//
//  CircleButton.swift
//  batagor
//
//  Created by Tude Maha on 03/11/2025.
//

import SwiftUI

struct CircleButton: View {
    var icon: String
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Image(systemName: icon)
                    .bold()
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
            } else {
                Image(systemName: icon)
                    .bold()
                    .frame(width: 44, height: 44)
                    .background(.thickMaterial)
                    .clipShape(.circle)
            }
        }
    }
}

#Preview {
    CircleButton(icon: "chevron.backward")
}
