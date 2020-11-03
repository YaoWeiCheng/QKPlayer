//
//  QKPlayerPresentView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/6.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit
import AVFoundation


class QKPlayerPresentView: QKPlayerView {
        
    var player: AVPlayer? {
        willSet (player) {
            if player == self.player { return }
            self.avLayer().player = player
        }
    }
    // 视频内容显示模式
    var videoGravity: AVLayerVideoGravity? {
        get {
            return self.avLayer().videoGravity
        }
        set (value){
            if value == videoGravity { return }
            guard let value = value else { return }
            self.avLayer().videoGravity = value
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    // 获取当前layer
    private func avLayer() -> AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }

}
