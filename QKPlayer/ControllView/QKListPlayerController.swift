//
//  QKListPlayerController.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/20.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit


class QKListPlayerController: UIView {
    
    // 控制view
    private(set) var portraitControlView = QKListPortraitControllerView()

    // 加载loading
    private(set) var activityView = QKSpeedLoadingView()
    // 加载失败按钮
    private(set) var failBtn = UIButton()
    // 是否显示了控制层
    private(set) var isShowing = false
    // 是否播放结束
    private(set) var isPlayEnd = false
    // 控制层显示或者隐藏
    private(set) var isControlViewAppeared = false
    // 总时间
    private(set) var sumTime: TimeInterval = 0
    // 如果是暂停状态，seek完进度后是否播放，默认true
    public var isSeekToPlay = true {
        didSet {
            self.portraitControlView.isSeekToPlay = oldValue
        }
    }
    // 控制层显示或者隐藏的回调
    public var controlViewAppearedCallback: ((Bool)->Void)?
    // 控制层自动隐藏的动画时间, 默认2.5
    public var autoHiddenTimeInterval: TimeInterval = 2.5
    // 控制层显示或者隐藏的动画时间，默认0.25
    public var autoFadeTimeInterval = 0.25
    // 横向滑动控制播放进度时，是否显示控制层 默认true
    public var horizontalPanShowcontrolView = true
    // prepare时候是否显示控制层，默认false
    public var prepareShowControlView = false
    // prepare时是否显示loading，默认false
    public var prepareShowLoading = false
    // 双击pause时是否显示控制层
    public var pauseShowControlView = true
    
    private var afterBlock: DispatchWorkItem?
    // 音量与光源
    private lazy var volumeBrightnessView: QKVolumeBrightnessView = {
        let volumeBrightnessView = QKVolumeBrightnessView()
        volumeBrightnessView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        volumeBrightnessView.isHidden = true
        return volumeBrightnessView
    }()
    
    private weak var _player: QKPlayerController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(volumeChanged),
                                               name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
                                               object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        self.cancelAutoFadeOutControlView()
//        print("\(self) deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var min_x = 0
        var min_y = 0
        var min_w = 0
        var min_h = 0
        //        let min_view_w = self.frame.width
        //        let min_view_h = self.frame.height
        
        self.portraitControlView.frame = self.bounds
        
        min_w = 80
        min_h = 80
        self.activityView.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        self.activityView.center.x = self.center.x
        self.activityView.center.y = self.center.y + 10
        
        min_w = 150
        min_h = 30
        self.failBtn.frame = CGRect(x: min_x, y: min_y, width: min_w, height: min_h)
        self.failBtn.center = self.center
        
        min_x = 0
        min_y = QKPlayer_IsIphoneX ? 54 : 30
        min_w = 170
        min_h = 35
        self.volumeBrightnessView.frame = CGRect(x: min_x, y: min_h, width: min_w, height: min_h)
        self.volumeBrightnessView.center.x = self.center.x
    }
    
    // MARK: - 创建UI
    func setupUI() {
        
        self.addSubview(self.portraitControlView)
        portraitControlView.sliderValueChanging = { [weak self](value, isForward) in
            self?.cancelAutoFadeOutControlView()
        }
        portraitControlView.sliderValueChanged = { [weak self](value) in
            self?.autoFadeOutControlView()
        }
        
        self.addSubview(self.activityView)
        self.addSubview(self.failBtn)
        self.failBtn.setTitle("加载失败，点击重试", for: .normal)
        self.failBtn.setTitleColor(.white, for: .normal)
        self.failBtn.titleLabel?.font = .systemFont(ofSize: 14)
        self.failBtn.backgroundColor = UIColor(white: 0, alpha: 0.7)
        self.failBtn.isHidden = true
        failBtn.addTarget(self, action: #selector(failClickAction), for: .touchUpInside)
        
        resetControlView()
    }
    
    func autoFadeOutControlView() {
        self.isControlViewAppeared = true
        cancelAutoFadeOutControlView()
        if let controlViewAppearedCallback = self.controlViewAppearedCallback {
            controlViewAppearedCallback(true)
        }
        
        self.afterBlock = DispatchWorkItem(block: { [weak self]() in
            self?.hiddenControlView(animate: true)
        })
        
        guard let afterBlock = self.afterBlock else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.autoHiddenTimeInterval, execute: afterBlock)
    }
    
    // MARK: - 取消block动画
    func cancelAutoFadeOutControlView() {
        if let afterBlock = self.afterBlock {
            afterBlock.cancel()
        }
        self.afterBlock = nil
    }
    
    // MARk: - 隐藏控制层
    func hiddenControlView(animate: Bool) {
        self.isControlViewAppeared = false
        if let controlViewAppearedCallback = self.controlViewAppearedCallback {
            // 回调当前控制层的状态
            controlViewAppearedCallback(false)
        }
        
        UIView.animate(withDuration: animate ? self.autoFadeTimeInterval : 0) {
            self.portraitControlView.hiddenControlView()
        }
    }
    
    // MARK: - 显示控制层
    func showControlView(animate: Bool) {
        self.isControlViewAppeared = true
        if let controlViewAppearedCallback = self.controlViewAppearedCallback {
            controlViewAppearedCallback(self.isControlViewAppeared)
        }
        autoFadeOutControlView()
        UIView.animate(withDuration: animate ? self.autoFadeTimeInterval : 0) {
            self.portraitControlView.showControlView()
        }
    }
    
    // MARK: - Action
    
    // 音量监听通知回调
    @objc func volumeChanged(notice: Notification) {
        let userInfo = notice.userInfo
        let resonStr = userInfo?["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String
        if resonStr == "ExplicitVolumeChange" {
            let volume = userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? CGFloat
            if self.player?.isFullScreen == true {
                if let volume = volume {
                    self.volumeBrightnessView.update(progress: volume, type: .volum)
                }
            } else {
                self.volumeBrightnessView.addSystemVolumeView()
            }
        }
        
    }
    
    // MARK: - 播放失败重试
    @objc func failClickAction(btn: UIButton) {
        self.player?.currentPlayerManager?.reloadPlayer()
    }
    
    // MARK: - Public method
    func resetControlView() {
        self.portraitControlView.resetControlView()
        self.cancelAutoFadeOutControlView()
        self.portraitControlView.isHidden = self.player?.isFullScreen == true
        self.failBtn.isHidden = true
        self.volumeBrightnessView.isHidden = true
        if isControlViewAppeared {
            self.showControlView(animate: false)
        } else {
            self.hiddenControlView(animate: false)
        }
        
    }
    
    func showControlView() {
        if self.prepareShowControlView {
            self.showControlView(animate: false)
        } else {
            self.hiddenControlView(animate: false)
        }
    }
}

extension QKListPlayerController: QKPlayerMediaControl {
    
    var player: QKPlayerController? {
        get {
            return _player
        }
        set {
            _player = newValue
            self.portraitControlView.player = newValue
        }
    }
    
    // MARK: - QKPlayerMediaControl
    
    // 播放状态发生改变
    func videoPlayer(playerControl: QKPlayerController, playStateChanged state: QKPlayerPlaybackState) {
        if state == .playing {
            self.portraitControlView.playBtnSelectedState(selected: true)
            self.failBtn.isHidden = true
            // 开始播放时 判断是否显示loading
            if playerControl.currentPlayerManager?.loadState == QKPlayerLoadState.stalled && !self.prepareShowLoading {
                self.activityView.startAnimating()
            } else if (playerControl.currentPlayerManager?.loadState == QKPlayerLoadState.stalled ||
                playerControl.currentPlayerManager?.loadState == QKPlayerLoadState.prepare) &&
                self.prepareShowLoading {
                self.activityView.startAnimating()
            }
        } else if state == .paused {
            self.portraitControlView.playBtnSelectedState(selected: false)
            // 暂停的时候隐藏loading
            self.activityView.stopAnimating()
            self.failBtn.isHidden = true
        } else if state == .playFailed {
            self.failBtn.isHidden = false
            self.activityView.stopAnimating()
        }
        
    }
    
    /// 播放加载状态发生改变时
    func videoPlayer(playerControl: QKPlayerController, loadStateChange state: QKPlayerLoadState) {
        if state == .prepare {
            self.portraitControlView.playBtnSelectedState(selected: playerControl.currentPlayerManager?.shouldAutoPlay ?? false)
        }
        
        if state == .stalled && playerControl.currentPlayerManager?.isPlaying == true && !self.prepareShowLoading {
            self.activityView.startAnimating()
        } else if (state == .stalled || state == .prepare) && playerControl.currentPlayerManager?.isPlaying == true && self.prepareShowLoading {
            print("state: \(state) - startAnimating")
            self.activityView.startAnimating()
        } else {
            self.activityView.stopAnimating()
        }
    }
    
    /// 播放回调时
    func videoPlayer(playerControl: QKPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) {
        self.portraitControlView.videoPlayer(playerControl: playerControl, currentTime: currentTime, totalTime: totalTime)
    }
    
    /// 当播放缓存发生改变时
    func videoPlayer(playerControl: QKPlayerController, bufferTime: TimeInterval) {
        self.portraitControlView.videoPlayer(playerControl: playerControl, bufferTime: bufferTime)
    }
    
    
    // MARK: - Gesture
    
    /// 单击回调
    func gestureSingleTap(gestureControl: QKPlayerGestureControl) {
        if self.player == nil { return }
        if self.isControlViewAppeared {
            self.hiddenControlView(animate: true)
        } else {
            self.hiddenControlView(animate: false)
            self.showControlView(animate: true)
        }
    }
    
    /// 双击回调
    func gestureDoubleTap(gestureControl: QKPlayerGestureControl) {
        self.portraitControlView.playOrPause()
        if pauseShowControlView {
            showControlView(animate: true)
        }
    }
}


