//
//  PlainAVPlayer.swift
//  batagor
//
//  Created by Tude Maha on 11/11/2025.
//

import SwiftUI
import AVKit

struct PlainAVPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> some UIView {
        return PlayerUIView(player: player)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

private class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
