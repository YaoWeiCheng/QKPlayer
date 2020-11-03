//
//  QKListCollectionViewCell.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/18.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKListCollectionViewCell: UICollectionViewCell {

    var containerView: UIImageView = UIImageView()
    let playBtn = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.containerView.frame = CGRect(x: 0, y: 0, width: QKPlayer_ScreenWidth, height: self.bounds.height - 50)

    }
    
    // MARK: - 创建UI
    func setupUI() {
        
        self.contentView.addSubview(self.containerView)
        self.containerView.tag = 100
        self.containerView.backgroundColor = .black
        
        let size: CGFloat = 40
        let x = (QKPlayer_ScreenWidth - size) / 2
        let y = (containerView.frame.height - size) / 2
        self.containerView.addSubview(self.playBtn)
        self.playBtn.frame = CGRect(x: x, y: y, width: 40, height: 40)
        self.playBtn.setImage(UIImage(named: "icon_big_play"), for: .normal)
        playBtn.isUserInteractionEnabled = false
        playBtn.center = self.contentView.center
//        self.playBtn.addTarget(self, action: #selector(playClickAction), for: .touchUpInside)
        
    }
    
}

