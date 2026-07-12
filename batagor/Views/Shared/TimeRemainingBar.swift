//
//  TimeRemainingBar.swift
//  batagor
//
//  Created by Tude Maha on 14/11/2025.
//

import SwiftUI

struct TimeRemainingBar: View {
    var storage: Storage
    var showText: Bool = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .black.opacity(0.6), location: 0.0),
                    Gradient.Stop(color: .black.opacity(0.3), location: 0.5),
                    Gradient.Stop(color: .clear, location: 1.0)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 80)
            
            ProgressView(value: Double(storage.timeRemaining), total: 86400)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.blueBase))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .frame(height: 6)
            
            if showText {
                VStack {
                    HStack {
                        RemainingTime(storage: storage, variant: .small)
                        
                        Spacer()

                        HStack {
                                if let locationName = storage.locationName {
                                    Text(locationName)
                                        .font(.spaceGroteskRegular(size: 13))
                                        .foregroundColor(Color.lightBase)
                                } else {
                                    Text("Location Unknown")
                                        .font(.spaceGroteskRegular(size: 13))
                                        .foregroundColor(Color.lightBase)
                                }
                            }
                            .padding(.horizontal, 8)
                        
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 12,
                    bottomTrailing: 12,
                    topTrailing: 0
                )
            )
        )
    }
}

#Preview {
    TimeRemainingBar(storage:
        Storage(
            mainPath: URL(string: "https://example.com")!,
            thumbnailPath: URL(string: "https://example.com")!
        ))
    
}
