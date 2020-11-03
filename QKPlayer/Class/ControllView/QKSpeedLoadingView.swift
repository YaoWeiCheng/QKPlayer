//
//  QKSpeedLoadingView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/8.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKSpeedLoadingView: UIView {

    public var loadingView = QKLoadingView()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 创建UI
    func setupUI() {
        self.isUserInteractionEnabled = false
        self.addSubview(self.loadingView)
        self.loadingView.lineWidth = 0.8
        self.loadingView.duration = 1
        self.loadingView.hidesWhenStoped = true
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var min_x: CGFloat = 0
        var min_y: CGFloat = 0
        var min_w: CGFloat = 0
        var min_h: CGFloat = 0
        let min_view_w: CGFloat = self.frame.width
        let min_view_h: CGFloat = self.frame.height
        
        min_w = 44
        min_h = min_w
        min_x = (min_view_w - min_w) / 2
        min_y = (min_view_h - min_h) / 2 - 10
        self.loadingView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
    }
    
    // MARK: - Public Method
    
    // MARK: - 开始动画
    public func startAnimating() {
        
        self.loadingView.startAnimating()
        self.isHidden = false
    }

    // MARK: - 结束动画
    public func stopAnimating() {
        self.loadingView.stopAnimating()
        self.isHidden = true
    }
}
