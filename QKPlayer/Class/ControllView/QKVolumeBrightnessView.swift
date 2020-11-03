//
//  QKVolumeBrightnessView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/13.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit
import MediaPlayer

enum QKVolumeBrightnessType {
    case volum
    case brightness
}

class QKVolumeBrightnessView: UIView {

    // 类型
    private(set) var volumeBrightnessType = QKVolumeBrightnessType.volum {
        didSet {
            if oldValue == .volum {
                self.iconImageView.image = QKUtils.imageName(name: "QKPlayer_volume")
            } else {
                self.iconImageView.image = QKUtils.imageName(name: "QKPlayer_brightness")
            }
        }
    }
    // 进度条
    private(set) lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progressTintColor = .white
        progressView.trackTintColor = UIColor.lightGray.withAlphaComponent(0.4)
        return progressView
    }()
    // 图标
    var iconImageView = UIImageView()
    //
    private lazy var volumeView: MPVolumeView = {
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100))
        return volumeView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        hidenTipsView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var min_x: CGFloat = 0
        var min_y: CGFloat = 0
        var min_w: CGFloat = 0
        var min_h: CGFloat = 0
        let min_view_w: CGFloat = self.frame.width
        let min_view_h: CGFloat = self.frame.height
        let margin: CGFloat = 10
        
        min_x = margin
        min_w = 20
        min_h = min_w
        min_y = (min_view_h - min_h) / 2
        self.iconImageView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_x = self.iconImageView.frame.maxX + margin
        min_h = 2
        min_y = (min_view_h - min_h) / 2
        min_w = min_view_w - min_x - margin
        self.progressView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        self.layer.cornerRadius = min_view_h / 2
        self.layer.masksToBounds = true
    }
    
    // MARK: - 创建UI
    func setupUI() {
        
        self.addSubview(self.iconImageView)
        self.addSubview(self.progressView)
    }
    
    // MARK: - 隐藏提示view
    @objc func hidenTipsView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0
        }) { (finished) in
            self.isHidden = true
        }
    }
    
    
    // MARK: - Public method
    
    // MARK: - 更新进度
    public func update(progress: CGFloat, type: QKVolumeBrightnessType) {
        var _progress = progress
        if _progress >= 1 {
            _progress = 1
        } else if (_progress <= 0){
            _progress = 0
        }
        self.progressView.progress = Float(_progress)
        self.volumeBrightnessType = type
        var playerImage: UIImage?
        if type == .volum {
            if _progress == 0 {
                playerImage = QKUtils.imageName(name: "QKPlayer_muted")
            } else if _progress > 0 && progress < 0.5 {
                playerImage = QKUtils.imageName(name: "QKPlayer_volume_low")
            } else {
                playerImage = QKUtils.imageName(name: "QKPlayer_volume_high")
            }
        } else if type == .brightness {
            if _progress >= 0 && _progress < 0.5 {
                playerImage = QKUtils.imageName(name: "QKPlayer_brightness_low")
            } else {
                playerImage = QKUtils.imageName(name: "QKPlayer_brightness_high")
            }
        }
        
        self.iconImageView.image = playerImage
        self.isHidden = false
        self.alpha = 1
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hidenTipsView), object: nil)
        self.perform(#selector(hidenTipsView), with: nil, afterDelay: 1.5)
        
    }
    
    // MARK: - 添加系统音量
    public func addSystemVolumeView() {
        self.volumeView.removeFromSuperview()
    }
    
    // MARK: - 移除系统音量
    public func removeSystemVolumeView() {
        UIApplication.shared.keyWindow?.addSubview(self.volumeView)
    }
    

}
