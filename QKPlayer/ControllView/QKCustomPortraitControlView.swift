//
//  QKCustomPortraitControlView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/7.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKCustomPortraitControlView: UIView {

    // 底部工具栏
    private(set) var bottomToolView = UIView()
    // 顶部工具栏
    private(set) var topToopView = UIView()
    // 标题
    private(set) var titleLabel = UILabel()
    // 返回按钮
    private(set) var backBtn = UIButton()
    // 播放或暂停按钮
    private(set) var playOrPauseBtn = UIButton()
    // 播放的当前时间
    private(set) var currentTimeLabel = UILabel()
    // 滑杆
    private(set) var sliderView = QKSliderView()
    // 视频总时间
    private(set) var totalTimeLabel = UILabel()
    // 全屏按钮
    private(set) var fullScreenBtn = UIButton()
    // 静音按钮
    private(set) var muteBtn = UIButton()
    // 底部栏暂停播放按钮
    private(set) var bottomPlayOrPauseBtn = UIButton()
    // 播放器
    public weak var player: QKPlayerController? {
        didSet {
            self.muteBtn.isSelected = self.player?.isMuted == true
        }
    }
    // 滑杆滑动中
    var sliderValueChanging: ((_ value: CGFloat,_ forword: Bool)->Void)?
    // 滑动结束
    var sliderValueChanged: ((_ value: CGFloat)->Void)?
    // 如果是暂停状态seek完后是否播放，默认true
    var isSeekToPlay = true
    
    var isShow: Bool = false

    
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
        let min_view_w: CGFloat = self.bounds.size.width
        let min_view_h: CGFloat = self.bounds.size.height
        let min_margin: CGFloat = 9
        
        
        min_x = 0
        min_y = 0
        min_w = 40
        min_h = 40
        self.playOrPauseBtn.frame = CGRect(x: 0, y: 0, width: min_w, height: min_h)
        self.playOrPauseBtn.center = self.center
        
        min_x = 0
        min_h = 40//44
        min_y = min_view_h - min_h
        min_w = min_view_w
        self.bottomToolView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_x = 10
        min_w = 20
        min_h = 20
        min_y = (self.bottomToolView.frame.height - min_h) / 2
        self.bottomPlayOrPauseBtn.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_x = self.bottomPlayOrPauseBtn.frame.maxX + min_margin
        min_w = 62
        min_h = 20
        min_y = (self.bottomToolView.frame.height - min_h) / 2
        self.currentTimeLabel.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_w = 20
        min_h = 20
        min_y = (self.bottomToolView.frame.height - min_h) / 2
        min_x = min_view_w - min_margin - min_w
        self.fullScreenBtn.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
     
        min_w = 20
        min_h = 20
        min_y = (self.bottomToolView.frame.height - min_h) / 2
        min_x = fullScreenBtn.frame.minX - min_margin - min_w
        self.muteBtn.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_w = 62
        min_h = 20
        min_y = (self.bottomToolView.frame.height - min_h) / 2
        min_x = muteBtn.frame.minX - 12 - min_w
        self.totalTimeLabel.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        
        min_x = currentTimeLabel.frame.maxX + min_margin
        min_w = QKPlayer_ScreenWidth - min_x - (QKPlayer_ScreenWidth - totalTimeLabel.frame.minX)
        min_h = 30
        min_y = (self.bottomToolView.frame.height - min_h) / 2
        self.sliderView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)

        if !self.isShow {
            self.bottomToolView.frame.origin.y = self.frame.height
            self.playOrPauseBtn.alpha = 0
        } else {
            self.bottomToolView.frame.origin.y = self.frame.height - self.bottomToolView.frame.height
            self.playOrPauseBtn.alpha = 1
        }
        
    }
    
    // MARK: - 创建UI
    func setupUI() {
        
        self.addSubview(self.topToopView)
        self.addSubview(bottomToolView)
        let image = QKUtils.imageName(name: "QKPlayer_bottom_shadow")
        bottomToolView.layer.contents = image?.cgImage
        
        self.addSubview(playOrPauseBtn)
        self.playOrPauseBtn.setImage(UIImage(named: "icon_big_play"), for: .normal)
        self.playOrPauseBtn.setImage(QKUtils.imageName(name: "new_allPause_44x44_"), for: .selected)
        
        self.bottomToolView.addSubview(self.bottomPlayOrPauseBtn)
        self.bottomPlayOrPauseBtn.setImage(UIImage(named: "icon_small_play"), for: .normal)
        self.bottomPlayOrPauseBtn.setImage(UIImage(named: "icon_pause"), for: .selected)
        
        self.bottomToolView.addSubview(self.currentTimeLabel)
        self.currentTimeLabel.text = "00:00"
        self.currentTimeLabel.textColor = .white
        self.currentTimeLabel.font = .systemFont(ofSize: 14)
        self.currentTimeLabel.textAlignment = .center
        
        self.bottomToolView.addSubview(self.sliderView)
        
        self.bottomToolView.addSubview(self.totalTimeLabel)
        self.totalTimeLabel.text = "00:00"
        self.totalTimeLabel.font = .systemFont(ofSize: 14)
        self.totalTimeLabel.textColor = .white
        self.totalTimeLabel.textAlignment = .center
        
        self.bottomToolView.addSubview(self.muteBtn)
        self.muteBtn.setImage(UIImage(named: "icon_ad"), for: .normal)
        self.muteBtn.setImage(UIImage(named: "icon_adun"), for: .selected)
        
        self.bottomToolView.addSubview(self.fullScreenBtn)
        self.fullScreenBtn.setImage(UIImage(named: "icon_full"), for: .normal)
        
        self.sliderView.delegate = self
        self.sliderView.maximunTrackTintColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.8)
        self.sliderView.bufferTrackTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        self.sliderView.minimunTrackTintColor = .white
        self.sliderView.setThumbImage(image: UIImage(named: "icon_progress"), state: .normal)
        self.sliderView.sliderHeight = 2
        makeSubviewsAction()
        
        self.clipsToBounds = true
        
        resetControlView()
        
    }
    
    // MARK: - 设置响应事件
    func makeSubviewsAction() {
        self.playOrPauseBtn.addTarget(self, action: #selector(playPauseClickAction), for: .touchUpInside)
        self.bottomPlayOrPauseBtn.addTarget(self, action: #selector(playPauseClickAction), for: .touchUpInside)
        self.fullScreenBtn.addTarget(self, action: #selector(fullScreeClickAction), for: .touchUpInside)
        self.muteBtn.addTarget(self, action: #selector(muteClickAction), for: .touchUpInside)
    }
    
    // MARK: - Action
    
    // MARK: 播放与暂停
    @objc func playPauseClickAction(btn: UIButton) {
        playOrPause()
    }
    
    // MARK: 全屏点击事件
    @objc func fullScreeClickAction(btn: UIButton) {
        self.player?.enterPortrait(fullScreen: true, animated: true)
    }
    // MARK: - 禁音操作
    @objc func muteClickAction(btn: UIButton) {
        playerMuteStatus()
    }
    
    // MARK: - Public Method
 
    // MARK: - 根据当前播放状态取反
    public func playOrPause() {
        
        self.playOrPauseBtn.isSelected = !self.playOrPauseBtn.isSelected
        self.playOrPauseBtn.isHidden = self.playOrPauseBtn.isSelected
        self.bottomPlayOrPauseBtn.isSelected = !self.bottomPlayOrPauseBtn.isSelected
        // 这里根据是否选中来判断播放或者暂停
        if self.playOrPauseBtn.isSelected == true {
            self.player?.currentPlayerManager?.play()
        } else {
            self.player?.currentPlayerManager?.pause()
        }
    }
    
    // MARK: - 播放按钮状态
    public func playBtnSelectedState(selected: Bool) {
        self.playOrPauseBtn.isSelected = selected
        self.playOrPauseBtn.isHidden = self.playOrPauseBtn.isSelected
        self.bottomPlayOrPauseBtn.isSelected = selected
        
    }
    
    // MARK - 禁音状态
    public func playerMuteStatus() {
        self.muteBtn.isSelected = !self.muteBtn.isSelected
        self.player?.isMuted = self.muteBtn.isSelected
    }
    
    // MARK: - 显示控制view
    public func showControlView() {
        self.bottomToolView.alpha = 1
        self.isShow = true
        self.bottomToolView.frame.origin.y = self.frame.height - self.bottomToolView.frame.height
        self.playOrPauseBtn.alpha = 1
        
//        self.player.st
        
    }
    
    // MARK: - 隐藏控制view
    public func hiddenControlView() {
        self.isShow = false
        self.bottomToolView.alpha = 0
        self.bottomToolView.frame.origin.y = self.frame.height
        self.playOrPauseBtn.alpha = 0
    }
    
    // MARK: - 重置控制view
    public func resetControlView() {
        self.bottomToolView.alpha = 1
        self.sliderView.value = 0
        self.sliderView.bufferValue = 0
        self.currentTimeLabel.text = "00:00"
        self.totalTimeLabel.text = "00:00"
        self.backgroundColor = .clear
        self.playOrPauseBtn.isSelected = true
        self.bottomPlayOrPauseBtn.isSelected = true
        self.playOrPauseBtn.isHidden = self.playOrPauseBtn.isSelected
        
    }
    
    // MARK: - 设置播放时间
    public func videoPlayer(playerControl: QKPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) {
        if self.sliderView.isdragging == false {
            let curretTimeStr = QKUtils.converTimeSecond(timeSecond: Int(currentTime))
            self.currentTimeLabel.text = curretTimeStr
            let totalTimeStr = QKUtils.converTimeSecond(timeSecond: Int(totalTime))
            self.totalTimeLabel.text = totalTimeStr
            self.sliderView.value = playerControl.progress
        }
    }
    
    // MARK: - 设置缓存时间
    public func videoPlayer(playerControl: QKPlayerController, bufferTime: TimeInterval) {
        self.sliderView.bufferValue = playerControl.bufferProgress
    }
    
    // MARK: - 调节播放器slider和当前时间
    public func sliderValueChanged(value: CGFloat, curretTimeStr: String) {
        self.sliderView.value = value
        self.currentTimeLabel.text = curretTimeStr
        self.sliderView.isdragging = true
        UIView.animate(withDuration: 0.3) {
            // 拖动是缩放大小
            self.sliderView.sliderBtn.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
        }
    }
    
    // MARK: - 滑杆结束滑动
    public func sliderChangedEnded() {
        self.sliderView.isdragging = false
        UIView.animate(withDuration: 0.3) {
            self.sliderView.sliderBtn.transform = .identity
        }
    }
    
    // MARK: - 全屏模式
    public func showFullScreenModel(fullScreenModel: QKFullScreenMode) {
        self.player?.orientationObserver?.fullScreenMode = fullScreenModel
        
    }
}


extension QKCustomPortraitControlView: QKSliderViewChangeStateDelegate {
    
    func sliderTouchBegin(value: CGFloat) {
        self.sliderView.isdragging = true
    }
    
    func sliderValueChanged(value: CGFloat) {
        if self.player?.totalTime == 0 {
            self.sliderView.value = 0
            return 
        }
        self.sliderView.isdragging = true
        let time = (self.player?.totalTime ?? 0) * TimeInterval(value)
        let currentTimeStr = QKUtils.converTimeSecond(timeSecond: Int(time))
        self.currentTimeLabel.text = currentTimeStr
        if let sliderValueChanging = self.sliderValueChanging, let isForward = self.sliderView.isForward {
            sliderValueChanging(value, isForward)
        }
    }
    
    func sliderTouchEnd(value: CGFloat) {
        if (self.player?.totalTime ?? 0) > 0 {
            self.sliderView.isdragging = true
            if let sliderValueChanging = self.sliderValueChanging , let isForward = self.sliderView.isForward { sliderValueChanging(value, isForward)}
            self.player?.seekTime(time: (self.player?.totalTime ?? 0) * TimeInterval(value), complectionHandler: { [weak self](isFinish) in
                if isFinish {
                    self?.sliderView.isdragging = false
                    if let sliderValueChanged = self?.sliderValueChanged {
                        sliderValueChanged(value)
                    }
                }
            })
            if self.isSeekToPlay {
                self.player?.currentPlayerManager?.play()
            }
        } else {
            self.sliderView.isdragging = false
            self.sliderView.value = 0
        }
    }
    
    func sliderTapped(value: CGFloat) {
        self.sliderTouchEnd(value: value)
        let time = (self.player?.totalTime ?? 0) * TimeInterval(value)
        let currentTimeStr = QKUtils.converTimeSecond(timeSecond: Int(time))
        self.currentTimeLabel.text = currentTimeStr
    }
}
