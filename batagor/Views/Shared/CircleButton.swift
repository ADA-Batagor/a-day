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
        Image(systemName: icon)
            .bold()
            .padding(15)
            .background(.thickMaterial)
            .clipShape(.circle)
    }
}

#Preview {
    CircleButton(icon: "chevron.backward")
}
