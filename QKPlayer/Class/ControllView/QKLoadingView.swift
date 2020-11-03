//
//  QKLoadingView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/8.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

enum QKLoadingType {
    case none
}

class QKLoadingView: UIView {

    
    private var shapeLayer: CAShapeLayer = CAShapeLayer()
    
    public var loadingType = QKLoadingType.none
    // 颜色颜色
    public var lineColor: UIColor = .white {
        didSet {
            self.shapeLayer.strokeColor = self.lineColor.cgColor
        }
    }
    // 线的宽度
    public var lineWidth: CGFloat = 1 {
        didSet {
            self.shapeLayer.lineWidth = self.lineWidth
        }
    }
    // 动画时间
    public var duration: TimeInterval = 1
    //
    public var hidesWhenStoped: Bool? {
        didSet {
            self.isHidden = !self.animating && oldValue == true
        }
    }
    // 动画状态
    private var animating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUI() {
        
        self.layer.addSublayer(self.shapeLayer)
        shapeLayer.strokeColor = self.lineColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeStart = 0.1
        shapeLayer.strokeEnd = 1
        shapeLayer.lineCap = CAShapeLayerLineCap(rawValue: "round")
        shapeLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5) // 锚点
        self.isUserInteractionEnabled = false
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = min(self.bounds.width, self.bounds.height)
        let height = width
        self.shapeLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        let center = CGPoint(x: self.bounds.midX, y: self.self.bounds.midY) //CGPoint(x: self.bounds.minX, y: self.bounds.minY)
        let radius = min(self.frame.width / 2, self.frame.height / 2) - self.lineWidth / 2
        let startAngle = CGFloat(0)
        let endAngle = 2 * CGFloat.pi
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.shapeLayer.path = path.cgPath
    }
    
    // MARK: - Public Method
    
    // MARK: - 开始
    func startAnimating() {
        if self.animating { return }
        self.animating = true
        let ani = CABasicAnimation(keyPath: "transform.rotation.z")
        ani.toValue = CGFloat.pi * 2
        ani.duration = self.duration
        ani.repeatCount = Float.greatestFiniteMagnitude
        ani.isRemovedOnCompletion = false
        self.shapeLayer.add(ani, forKey: "rotation")
        if let hidesWhenStoped = self.hidesWhenStoped, hidesWhenStoped == true {
            self.isHidden = false
        }
    }
    
    // MARK: - 结束
    func stopAnimating() {
        if self.animating == false { return }
        self.animating = false
        self.shapeLayer.removeAllAnimations()
        if let hidesWhenStoped = self.hidesWhenStoped, hidesWhenStoped == true {
            self.isHidden = true
        }
    }
    
}
