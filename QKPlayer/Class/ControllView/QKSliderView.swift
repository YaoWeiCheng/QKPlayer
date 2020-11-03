//
//  QKSliderView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/7.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

// 滑块默认大小
let kSliderSize: CGFloat = 12
// 进度高度
let kProgressHeight: CGFloat = 1.0
// 拖动slider的动画时间
let kAnimate = 0.3

class QKSliderButton: UIButton {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var bounds = self.bounds
        // 扩大点击区域
        bounds = bounds.insetBy(dx: -20, dy: -20)
        // 若点击的点在新的bounds里面，就返回yes
        return bounds.contains(point)
    }
}

@objc protocol QKSliderViewChangeStateDelegate: NSObjectProtocol {
    // 滑块开始滑动时
    @objc optional func sliderTouchBegin(value: CGFloat)
    // 滑块滑动时
    @objc optional func sliderValueChanged(value: CGFloat)
    // 滑块结束时
    @objc optional func sliderTouchEnd(value: CGFloat)
    // 点击滑杆
    @objc optional func sliderTapped(value: CGFloat)
}


class QKSliderView: UIView {
    // 滑块状态代理
    weak var delegate: QKSliderViewChangeStateDelegate?
    // 进度背景
    private var bgProgressView = UIImageView()
    // 缓冲进度
    private var bufferProgressView = UIImageView()
    // 滑动进度
    private var sliderProgressView = UIImageView()
    // 加载view
    private var loadingBarView = UIView()
    // 是否加载中
    private var isLoading = false
    // 手势
    private var tapGesture: UITapGestureRecognizer?
    
    // ----------------- Public 属性 -----------------
    // 滑块
    private(set) var sliderBtn = QKSliderButton()
    // 滑杆颜色
    public var maximunTrackTintColor: UIColor? {
        didSet {
            if let maximunTrackTintColor = self.maximunTrackTintColor {
                self.bgProgressView.backgroundColor = maximunTrackTintColor
            }
        }
    }
    // 滑杆进度颜色
    public var minimunTrackTintColor: UIColor? {
        didSet {
            if let minimunTrackTintColor = self.minimunTrackTintColor {
                self.sliderProgressView.backgroundColor = minimunTrackTintColor
            }
        }
    }
    // 缓存进度颜色
    public var bufferTrackTintColor: UIColor? {
        didSet {
            if let bufferTrackTintColor = self.bufferTrackTintColor {
                self.bufferProgressView.backgroundColor = bufferTrackTintColor
            }
        }
    }
    // loading进度颜色
    public var loadingTintColor: UIColor? {
        didSet {
            if let loadingTintColor = self.loadingTintColor {
                self.loadingBarView.backgroundColor = loadingTintColor
            }
        }
    }
    // 默认滑杆颜色
    public var maxinumTrackImage: UIImage? {
        didSet {
            if let maxinumTrackImage = self.maxinumTrackImage {
                self.bgProgressView.image = maxinumTrackImage
                self.maximunTrackTintColor = .clear
            }
        }
    }
    // 滑杆进度的图片
    public var mininumTrackImage: UIImage? {
        didSet {
            if let mininumTrackImage = self.mininumTrackImage {
                self.sliderProgressView.image = mininumTrackImage
                self.minimunTrackTintColor = .clear
            }
        }
    }
    // 缓存进度的图片
    public var bufferTrackImage: UIImage? {
        didSet {
            if let bufferTrackImage = self.bufferTrackImage {
                self.bufferProgressView.image = bufferTrackImage
            }
            self.bufferTrackTintColor = .clear
        }
    }
    // 滑杆进度
    public var value: CGFloat = 0 {
        willSet {
            var _value = min(1.0, newValue)
            _value = _value >= 1.0 ? 1.0 : _value <= 0.0 ? 0.0 : _value
            self.value = _value
            if self.sliderBtn.isHidden {
                self.sliderProgressView.frame.size.width = self.bgProgressView.frame.width * _value
            } else {
                self.sliderBtn.center.x = self.bgProgressView.frame.width * _value
                self.sliderProgressView.frame.size.width = self.sliderBtn.center.x
            }
        }
    }
    // 缓存进度
    public var bufferValue: CGFloat = 0 {
        willSet {
            if newValue.isNaN { return }
            
            var _value = min(1.0, newValue)
            _value = _value >= 1.0 ? 1.0 : _value <= 0.0 ? 0.0 : _value
            self.bufferValue = _value
            self.bufferProgressView.frame.size.width = self.bgProgressView.frame.width * _value
        }
    }
    // 是否允许点击，默认是true
    public var allowTapped = true {
        didSet {
            if oldValue == false {
                guard let tapGestrue = self.tapGesture else { return }
                self.removeGestureRecognizer(tapGestrue)
            }
        }
    }
    // 是否允许点击动画, 默认是true
    public var allowAnimate = true
    // 设置滑杆高度
    public var sliderHeight: CGFloat = kProgressHeight {
        didSet {
            self.bgProgressView.frame.size.height = oldValue
            self.bufferProgressView.frame.size.height = oldValue
            self.sliderProgressView.frame.size.height = oldValue
        }
    }
    // 设置滑杆的圆角
    public var sliderRadius: CGFloat = 0 {
        didSet {
            self.bgProgressView.layer.cornerRadius = oldValue
            self.bgProgressView.layer.masksToBounds = true
            self.bufferProgressView.layer.cornerRadius = oldValue
            self.bufferProgressView.layer.masksToBounds = true
            self.sliderProgressView.layer.cornerRadius = oldValue
            self.sliderProgressView.layer.masksToBounds = true
            
        }
    }
    // 是否隐藏滑块 默认false
    public var isHiddenSliderBlock = false {
        didSet {
            self.sliderBtn.isHidden = oldValue
            if oldValue {
                self.bgProgressView.frame.origin.x = 0
                self.sliderProgressView.frame.origin.x = 0
                self.bufferProgressView.frame.origin.x = 0
                self.allowTapped = false
            }
        }
    }
    // 是否正在拖动
    public var isdragging: Bool = false
    // 向前拖动，还是向后拖动
    public var isForward: Bool?
    // 滑块大小尺寸
    public var thumbSize: CGSize = CGSize(width: kSliderSize, height: kSliderSize)
    
    // ----------------- end -----------------

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
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
        
        min_x = 0
        min_w = min_view_w
        min_h = self.sliderHeight
        min_y = (min_view_h - min_h) / 2
        self.bgProgressView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_x = 0
        min_w = self.thumbSize.width
        min_h = self.thumbSize.height
        min_y = (min_view_h - min_h) / 2
        self.sliderBtn.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        self.sliderBtn.center.x = self.bgProgressView.frame.width * value
     
        min_x = 0
        if sliderBtn.isHidden {
            min_w = self.bgProgressView.frame.width * value
        } else {
            min_w = self.sliderBtn.center.x
        }
        min_h = self.sliderHeight
        min_y = (min_view_h - min_h) / 2
        self.sliderProgressView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_x = 0
        min_w = self.bufferValue * self.bgProgressView.frame.width
        min_h = self.sliderHeight
        min_y = (min_view_h - min_h) / 2
        self.bufferProgressView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_w = 0.1
        min_h = self.sliderHeight
        min_x = (min_view_w - min_w) / 2
        min_y = (min_view_h - min_h) / 2
        self.loadingBarView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        
    }
    
    // MARK: - 创建UI
    func setupUI() {
        
        self.backgroundColor = .clear
        self.addSubview(bgProgressView)
        self.bgProgressView.backgroundColor = .gray
        self.bgProgressView.contentMode = .scaleAspectFill
        bgProgressView.clipsToBounds = true
        
        self.addSubview(bufferProgressView)
        self.bufferProgressView.backgroundColor = .white
        self.bufferProgressView.contentMode = .scaleAspectFill
        self.bufferProgressView.clipsToBounds = true
        
        self.addSubview(sliderProgressView)
        self.sliderProgressView.backgroundColor = .red
        self.sliderProgressView.contentMode = .scaleAspectFill
        self.sliderProgressView.clipsToBounds = true
        
        self.addSubview(sliderBtn)
        self.sliderBtn.adjustsImageWhenHighlighted = false
        
        self.addSubview(loadingBarView)
        self.loadingBarView.backgroundColor = .white
        self.loadingBarView.isHidden = true
        
        // 添加点击手势
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(tap:)))
        self.addGestureRecognizer(self.tapGesture!)
        
        // 添加滑动手势
        let sliderGesture = UIPanGestureRecognizer(target: self, action: #selector(sliderTapGestrueClickAction))
        self.addGestureRecognizer(sliderGesture)
    }
    
    // MARK: - Action
    
    // MARK: - 滑块手势
    @objc func sliderTapGestrueClickAction(tap: UITapGestureRecognizer) {
        
        if tap.state == .began {
            sliderBtnTouchBegin(btn: self.sliderBtn)
        } else if tap.state == .changed {
            sliderBtnTouchDragMoving(btn: self.sliderBtn, touchPoint: tap.location(in: self.bgProgressView))
        } else if tap.state == .ended {
            sliderBtnTouchEnd(btn: self.sliderBtn)
        }
    }
    
    // MARK: - 滑动开始
    func sliderBtnTouchBegin(btn: UIButton) {
        
        if let delegate = self.delegate, let sliderTouchBegin = delegate.sliderTouchBegin {
            sliderTouchBegin(self.value)
        }
        if self.allowAnimate {
            UIView.animate(withDuration: kAnimate) {
                btn.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
            }
        }
    }
    
    // MARK: - 滑动移动中
    func sliderBtnTouchDragMoving(btn: UIButton, touchPoint: CGPoint) {

        // 点击位置
        let point = touchPoint
        // 获取进度值
        var value = (point.x - btn.frame.width * 0.5) / self.bgProgressView.frame.width
        // 限制值在0-1之间
        value = value >= 1.0 ? 1.0 : value <= 0.0 ? 0.0 : value
        if self.value == value { return }
        self.isForward = self.value < value // 向前，向后
        self.value = value
        
        if let delegate = self.delegate, let sliderValueChanged = delegate.sliderValueChanged {
            sliderValueChanged(self.value)
        }
    }
    
    // MARK: - 滑动滑动结束
    func sliderBtnTouchEnd(btn: UIButton) {
        
        if let delegate = self.delegate, let sliderTouchEnd = delegate.sliderTouchEnd {
            sliderTouchEnd(self.value)
        }
        if self.allowAnimate {
            UIView.animate(withDuration: kAnimate) {
                btn.transform = CGAffineTransform.identity
            }
        }
    }
    
    // MARK: - 点击了滑块
    @objc func sliderTapped(tap: UITapGestureRecognizer) {
        let point = tap.location(in: self.bgProgressView)
        // 获取进度
        var value = (point.x - self.sliderBtn.frame.width * 0.5) / self.bgProgressView.frame.width
        value = value >= 1.0 ? 1.0 : value <= 0.0 ? 0.0 : value
        self.value = value
        if let delegate = self.delegate, let sliderTapped = delegate.sliderTapped {
            sliderTapped(value)
        }
    }
    
    
    // MARK: - Public Method
    
    
    
    // MARK: - 设置slider的背景图片
    public func setBackgroudImage(image: UIImage, state: UIControl.State) {
        self.sliderBtn.setBackgroundImage(image, for: state)
    }
    
    // MARK: - 设置slider的图片
    func setThumbImage(image: UIImage?, state: UIControl.State) {
        self.sliderBtn.setImage(image, for: state)
    }
    
}
